// Copyright (c) Decisa. MIT licensed. See LICENSE.

import Foundation

#if canImport(AdServices)
import AdServices
#endif

/// The deferred-attribution signal read from the native platform on first launch.
struct DeferredSignal: Sendable {
    let platform: String?
    let mclid: String?
    let adservicesToken: String?
    let madid: String?

    static let empty = DeferredSignal(platform: nil, mclid: nil, adservicesToken: nil, madid: nil)
}

/// Reads the iOS deferred-attribution signal (AdServices token).
protocol DeferredSignalReading: Sendable {
    func getDeferredSignal() async -> DeferredSignal
}

/// Production reader: fetches the AdServices attribution token on a background queue.
final class DeferredSignalReader: DeferredSignalReading, @unchecked Sendable {
    func getDeferredSignal() async -> DeferredSignal {
        let token = await Self.fetchAdServicesToken()
        return DeferredSignal(
            platform: "ios",
            mclid: nil,
            adservicesToken: token,
            madid: nil
        )
    }

    /// Returns the AdServices attribution token on iOS 14.3+, or nil when the
    /// framework is unavailable or the call throws.
    private static func fetchAdServicesToken() async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let token = Self.readAdServicesTokenSync()
                continuation.resume(returning: token)
            }
        }
    }

    private static func readAdServicesTokenSync() -> String? {
        #if canImport(AdServices)
        if #available(iOS 14.3, macOS 11.1, *) {
            do {
                return try AAAttribution.attributionToken()
            } catch {
                return nil
            }
        }
        #endif
        return nil
    }
}
