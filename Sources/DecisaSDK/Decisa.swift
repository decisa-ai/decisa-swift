// Copyright (c) Decisa. MIT licensed. See LICENSE.

import Foundation

/// The Decisa mobile attribution SDK entry point.
///
/// Usage:
/// ```swift
/// Decisa.start(appKey: "dcs_app_...")
/// await Decisa.track(DecisaEvent.purchase(value: 49.90, currency: "USD"))
/// ```
///
/// The SDK authenticates with the PUBLIC `app_key` (`dcs_app_...`) only — never
/// a secret `dcs_ak_` / `dcs_sk_` key, which must never ship in a mobile binary.
/// Pixel membership is configured server-side in the Decisa dashboard.
@MainActor
public enum Decisa {
    private static var instance: DecisaClient?
    private static var initializationTask: Task<Void, Never>?

    private static let appKeyPrefix = "dcs_app_"

    /// The resolved attribution for this install, available after [initialize].
    public static var attribution: DecisaAttribution? {
        instance?.attribution
    }

    /// Whether [initialize] has run and bound a visitor id.
    public static var isInitialized: Bool {
        instance?.attribution != nil
    }

    /// Initializes the SDK. Idempotent within a process.
    public static func initialize(
        appKey: String,
        baseURL: URL? = nil
    ) async {
        if instance != nil {
            return
        }

        if initializationTask == nil {
            beginInitialization(appKey: appKey, baseURL: baseURL)
        }

        await initializationTask?.value
    }

    /// Starts SDK initialization without awaiting completion.
    ///
    /// Call synchronously from `App.init` before any UI that may emit events
    /// (for example a first-run paywall). Prefer this over wrapping
    /// [initialize] in an unstructured `Task` so [track] can wait for resolve.
    public static func start(appKey: String, baseURL: URL? = nil) {
        if instance != nil || initializationTask != nil {
            return
        }
        beginInitialization(appKey: appKey, baseURL: baseURL)
    }

    private static func beginInitialization(
        appKey: String,
        baseURL: URL?
    ) {
        initializationTask = Task { @MainActor in
            let resolvedBaseURL = baseURL ?? URL(string: "https://api.decisa.ai")!

            assert(
                appKey.hasPrefix(appKeyPrefix),
                "Decisa: appKey must be a public app key (starts with \"\(appKeyPrefix)\"). " +
                    "Never ship a secret dcs_ak_ / dcs_sk_ key in a mobile binary."
            )

            let client = DecisaClient(
                appKey: appKey,
                transport: DecisaTransport(baseURL: resolvedBaseURL),
                persistence: DecisaPersistence(),
                signalReader: DeferredSignalReader()
            )

            await client.resolveOrRestore()

            if instance == nil {
                instance = client
            }
        }
    }

    /// Associates the current visitor with a known identity.
    public static func identify(
        userId: String? = nil,
        email: String? = nil,
        phone: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil
    ) async -> Bool {
        await awaitInitialization()
        guard let client = instance else {
            return false
        }
        return await client.identify(
            userId: userId,
            email: email,
            phone: phone,
            firstName: firstName,
            lastName: lastName
        )
    }

    /// Records an in-app [event] via `POST /v1/track`.
    public static func track(_ event: DecisaEvent) async -> Bool {
        if let client = instance {
            return await client.track(event)
        }

        if let initializationTask {
            await initializationTask.value
            guard let client = instance else {
                return false
            }
            return await client.track(event)
        }

        return false
    }

    private static func awaitInitialization() async {
        if instance != nil {
            return
        }
        if let initializationTask {
            await initializationTask.value
        }
    }

    // MARK: - Testing seams

    #if DEBUG
    /// Injectable initializer for unit tests.
    static func initializeForTesting(
        appKey: String,
        baseURL: URL,
        transport: DecisaTransporting,
        persistence: DecisaPersisting,
        signalReader: DeferredSignalReading
    ) async {
        if instance != nil {
            return
        }

        if initializationTask == nil {
            beginInitializationForTesting(
                appKey: appKey,
                baseURL: baseURL,
                transport: transport,
                persistence: persistence,
                signalReader: signalReader
            )
        }

        await initializationTask?.value
    }

    static func startForTesting(
        appKey: String,
        baseURL: URL,
        transport: DecisaTransporting,
        persistence: DecisaPersisting,
        signalReader: DeferredSignalReading
    ) {
        if instance != nil || initializationTask != nil {
            return
        }
        beginInitializationForTesting(
            appKey: appKey,
            baseURL: baseURL,
            transport: transport,
            persistence: persistence,
            signalReader: signalReader
        )
    }

    static func waitForInitializationForTesting() async {
        await initializationTask?.value
    }

    private static func beginInitializationForTesting(
        appKey: String,
        baseURL: URL,
        transport: DecisaTransporting,
        persistence: DecisaPersisting,
        signalReader: DeferredSignalReading
    ) {
        initializationTask = Task { @MainActor in
            let client = DecisaClient(
                appKey: appKey,
                transport: transport,
                persistence: persistence,
                signalReader: signalReader
            )
            await client.resolveOrRestore()

            if instance == nil {
                instance = client
            }
        }
    }

    /// Resets the singleton. Test-only.
    static func resetForTesting() {
        initializationTask?.cancel()
        initializationTask = nil
        instance = nil
    }
    #endif
}

// MARK: - DecisaClient

final class DecisaClient: @unchecked Sendable {
    let appKey: String
    private let transport: DecisaTransporting
    private let persistence: DecisaPersisting
    private let signalReader: DeferredSignalReading

    private(set) var attribution: DecisaAttribution?
    private var madid: String?

    init(
        appKey: String,
        transport: DecisaTransporting,
        persistence: DecisaPersisting,
        signalReader: DeferredSignalReading
    ) {
        self.appKey = appKey
        self.transport = transport
        self.persistence = persistence
        self.signalReader = signalReader
    }

    func resolveOrRestore() async {
        let signal = await signalReader.getDeferredSignal()
        madid = signal.madid

        if persistence.hasResolved() {
            attribution = persistence.readAttribution()
                ?? DecisaAttribution.unmatched(generateFallbackVisitorId())
            return
        }

        attribution = await resolve(signal: signal)
        if let attribution {
            try? persistence.saveAttribution(attribution)
        }
    }

    func resolve(signal: DeferredSignal) async -> DecisaAttribution {
        let fallbackVisitorId = generateFallbackVisitorId()

        var body: [String: Any] = ["app_key": appKey]
        if let mclid = signal.mclid { body["mclid"] = mclid }
        if let token = signal.adservicesToken { body["adservices_token"] = token }

        let response = await transport.post(path: "/v1/resolve", body: body)

        if !response.isSuccess || response.isNoContent || response.data == nil {
            return DecisaAttribution.unmatched(fallbackVisitorId)
        }

        return DecisaAttribution.fromResolveData(
            response.data!,
            fallbackVisitorId: fallbackVisitorId
        )
    }

    func identify(
        userId: String?,
        email: String?,
        phone: String?,
        firstName: String?,
        lastName: String?
    ) async -> Bool {
        guard let visitorId = attribution?.visitorId else {
            return false
        }

        if let userId, !userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            try? persistence.saveExternalId(userId.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        let trimmedUserId = userId?.trimmingCharacters(in: .whitespacesAndNewlines)
        let externalId: String? = (trimmedUserId?.isEmpty == false)
            ? trimmedUserId
            : persistence.readExternalId()

        let emailHash = DecisaHashing.email(email)
        let phoneHash = DecisaHashing.phone(phone)
        let fnHash = DecisaHashing.text(firstName)
        let lnHash = DecisaHashing.text(lastName)

        let hasIdentity = emailHash != nil
            || phoneHash != nil
            || fnHash != nil
            || lnHash != nil
            || (externalId?.isEmpty == false)

        if !hasIdentity {
            return false
        }

        var body: [String: Any] = [
            "app_key": appKey,
            "visitor_id": visitorId,
        ]
        if let emailHash { body["email_sha256"] = emailHash }
        if let phoneHash { body["phone_sha256"] = phoneHash }
        if let fnHash { body["fn_sha256"] = fnHash }
        if let lnHash { body["ln_sha256"] = lnHash }
        if let externalId, !externalId.isEmpty { body["external_id"] = externalId }

        let response = await transport.post(path: "/v1/identify", body: body)
        return response.isSuccess
    }

    func track(_ event: DecisaEvent) async -> Bool {
        guard let attribution else {
            return false
        }

        var extraMetadata = attribution.utmMap()
        if let madid { extraMetadata["madid"] = madid }
        if let externalId = persistence.readExternalId(), !externalId.isEmpty {
            extraMetadata["external_id"] = externalId
        }

        let body = event.toTrackBody(
            visitorId: attribution.visitorId,
            appKey: appKey,
            extraMetadata: extraMetadata
        )

        let response = await transport.post(path: "/v1/track", body: body)
        return response.isSuccess
    }

    func generateFallbackVisitorId() -> String {
        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
        var result = "v_"
        for _ in 0 ..< 24 {
            result.append(alphabet.randomElement()!)
        }
        return result
    }
}
