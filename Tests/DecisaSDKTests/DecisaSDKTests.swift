// Copyright (c) Decisa. MIT licensed. See LICENSE.

import CryptoKit
import Foundation
import XCTest

@testable import DecisaSDK

// MARK: - Mocks

final class MockTransport: DecisaTransporting, @unchecked Sendable {
    var handler: ((String, [String: Any]) -> DecisaResponse)?
    private(set) var sentBodies: [[String: Any]] = []
    private(set) var sentPaths: [String] = []

    func post(path: String, body: [String: Any]) async -> DecisaResponse {
        sentPaths.append(path)
        sentBodies.append(body)
        return handler?(path, body) ?? .networkFailure
    }
}

final class MockPersistence: DecisaPersisting, @unchecked Sendable {
    private var resolved = false
    private var attribution: DecisaAttribution?
    private var externalId: String?

    func hasResolved() -> Bool { resolved }

    func saveAttribution(_ attribution: DecisaAttribution) throws {
        self.attribution = attribution
        resolved = true
    }

    func readAttribution() -> DecisaAttribution? { attribution }

    func saveExternalId(_ externalId: String) throws {
        self.externalId = externalId
    }

    func readExternalId() -> String? { externalId }

    func clear() throws {
        resolved = false
        attribution = nil
        externalId = nil
    }
}

struct MockSignalReader: DeferredSignalReading {
    let signal: DeferredSignal

    func getDeferredSignal() async -> DeferredSignal { signal }
}

// MARK: - Tests

@MainActor
final class DecisaSDKTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        Decisa.resetForTesting()
    }

    override func tearDown() async throws {
        Decisa.resetForTesting()
        try await super.tearDown()
    }

    func testInitializeResolvesMatchedInstallAndPersistsVisitorId() async {
        let transport = MockTransport()
        transport.handler = { path, _ in
            XCTAssertEqual(path, "/v1/resolve")
            return DecisaResponse(
                statusCode: 200,
                data: [
                    "visitor_id": "v_server_123",
                    "matched": true,
                    "match_type": "adservices",
                    "utm_source": "google",
                    "utm_campaign": "spring_sale",
                ],
                error: nil
            )
        }

        let persistence = MockPersistence()

        await Decisa.initializeForTesting(
            pixelKey: "dcs_px_abc",
            baseURL: URL(string: "https://api.decisa.ai")!,
            transport: transport,
            persistence: persistence,
            signalReader: MockSignalReader(
                signal: DeferredSignal(
                    platform: "ios",
                    mclid: nil,
                    adservicesToken: "tok_abc",
                    madid: nil
                )
            )
        )

        XCTAssertTrue(Decisa.isInitialized)
        XCTAssertEqual(Decisa.attribution?.visitorId, "v_server_123")
        XCTAssertEqual(Decisa.attribution?.matched, true)
        XCTAssertEqual(Decisa.attribution?.utmCampaign, "spring_sale")
        XCTAssertEqual(transport.sentBodies.first?["adservices_token"] as? String, "tok_abc")
        XCTAssertEqual(transport.sentBodies.first?["pixel_key"] as? String, "dcs_px_abc")
        XCTAssertTrue(persistence.hasResolved())
    }

    func testInitializeFallsBackToLocalVisitorIdOn204() async {
        let transport = MockTransport()
        transport.handler = { _, _ in
            DecisaResponse(statusCode: 204, data: nil, error: nil)
        }

        await Decisa.initializeForTesting(
            pixelKey: "dcs_px_abc",
            baseURL: URL(string: "https://api.decisa.ai")!,
            transport: transport,
            persistence: MockPersistence(),
            signalReader: MockSignalReader(signal: .empty)
        )

        XCTAssertEqual(Decisa.attribution?.matched, false)
        XCTAssertTrue(Decisa.attribution?.visitorId.hasPrefix("v_") == true)
    }

    func testIdentifyHashesEmailClientSideAndNeverSendsRawPII() async {
        let transport = MockTransport()
        var identifyBody: [String: Any]?

        transport.handler = { path, body in
            if path == "/v1/resolve" {
                return DecisaResponse(
                    statusCode: 200,
                    data: ["visitor_id": "v_1", "matched": false],
                    error: nil
                )
            }
            identifyBody = body
            return DecisaResponse(statusCode: 202, data: nil, error: nil)
        }

        await Decisa.initializeForTesting(
            pixelKey: "dcs_px_abc",
            baseURL: URL(string: "https://api.decisa.ai")!,
            transport: transport,
            persistence: MockPersistence(),
            signalReader: MockSignalReader(signal: .empty)
        )

        let ok = await Decisa.identify(
            userId: "user_42",
            email: "  Jane@Example.COM "
        )

        XCTAssertTrue(ok)
        let expectedHash = SHA256.hash(data: Data("jane@example.com".utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        XCTAssertEqual(identifyBody?["email_sha256"] as? String, expectedHash)
        XCTAssertEqual(identifyBody?["external_id"] as? String, "user_42")

        let bodyJSON = try! JSONSerialization.data(withJSONObject: identifyBody!)
        let bodyString = String(data: bodyJSON, encoding: .utf8)!
        XCTAssertFalse(bodyString.contains("Jane@Example.COM"))
        XCTAssertFalse(bodyString.contains("jane@example.com"))
    }

    func testTrackSendsCanonicalEventNameValueAndUtmMetadata() async {
        let transport = MockTransport()
        var trackBody: [String: Any]?

        transport.handler = { path, body in
            if path == "/v1/resolve" {
                return DecisaResponse(
                    statusCode: 200,
                    data: [
                        "visitor_id": "v_1",
                        "matched": true,
                        "utm_source": "meta",
                        "utm_campaign": "launch",
                    ],
                    error: nil
                )
            }
            trackBody = body
            return DecisaResponse(statusCode: 202, data: nil, error: nil)
        }

        await Decisa.initializeForTesting(
            pixelKey: "dcs_px_abc",
            baseURL: URL(string: "https://api.decisa.ai")!,
            transport: transport,
            persistence: MockPersistence(),
            signalReader: MockSignalReader(
                signal: DeferredSignal(
                    platform: "ios",
                    mclid: nil,
                    adservicesToken: nil,
                    madid: "IDFA-1234"
                )
            )
        )

        let ok = await Decisa.track(DecisaEvent.purchase(value: 49.90, currency: "USD"))

        XCTAssertTrue(ok)
        XCTAssertEqual(trackBody?["event_name"] as? String, "Purchase")
        XCTAssertEqual(trackBody?["value"] as? Double, 49.90)
        XCTAssertEqual(trackBody?["currency"] as? String, "USD")
        XCTAssertEqual(trackBody?["visitor_id"] as? String, "v_1")
        let eventId = trackBody?["event_id"] as? String
        XCTAssertNotNil(eventId)
        XCTAssertGreaterThanOrEqual(eventId!.count, 8)

        let metadata = trackBody?["metadata"] as? [String: Any]
        XCTAssertEqual(metadata?["utm_source"] as? String, "meta")
        XCTAssertEqual(metadata?["madid"] as? String, "IDFA-1234")
    }

    func testCustomEventMapsToCustomWithLabelInMetadata() {
        let event = DecisaEvent.custom("viewed_pricing")
        let body = event.toTrackBody(visitorId: "v_1", pixelKey: "dcs_px_abc")

        XCTAssertEqual(body["event_name"] as? String, "Custom")
        let metadata = body["metadata"] as? [String: Any]
        XCTAssertEqual(metadata?["custom_event_name"] as? String, "viewed_pricing")
    }

    func testInitializeIsIdempotent() async {
        let transport = MockTransport()
        var resolveCallCount = 0

        transport.handler = { path, _ in
            if path == "/v1/resolve" {
                resolveCallCount += 1
                return DecisaResponse(
                    statusCode: 200,
                    data: ["visitor_id": "v_1", "matched": false],
                    error: nil
                )
            }
            return .networkFailure
        }

        let persistence = MockPersistence()
        let signalReader = MockSignalReader(signal: .empty)

        await Decisa.initializeForTesting(
            pixelKey: "dcs_px_abc",
            baseURL: URL(string: "https://api.decisa.ai")!,
            transport: transport,
            persistence: persistence,
            signalReader: signalReader
        )

        await Decisa.initializeForTesting(
            pixelKey: "dcs_px_abc",
            baseURL: URL(string: "https://api.decisa.ai")!,
            transport: transport,
            persistence: persistence,
            signalReader: signalReader
        )

        XCTAssertEqual(resolveCallCount, 1)
    }
}
