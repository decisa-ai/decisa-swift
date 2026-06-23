// Copyright (c) Decisa. MIT licensed. See LICENSE.

import Foundation

/// A single in-app event to record via `Decisa.track`.
public struct DecisaEvent {
    /// Stable idempotency key for this event (>= 8 chars).
    public let eventId: String

    /// The canonical event name.
    public let name: DecisaEventName

    /// Monetary value as a decimal (e.g. 49.90). Sent as `value`.
    public let value: Double?

    /// ISO-4217 3-letter currency code (e.g. `USD`).
    public let currency: String?

    /// For custom events, the human-facing custom event label.
    public let customName: String?

    /// Optional canonical URL / deep-link for the event context.
    public let url: String?

    /// When the event occurred (ISO-8601).
    public let occurredAt: String?

    /// Marks the event as a test event (`is_test: true`).
    public let isTest: Bool

    /// Free-form metadata stored verbatim by the backend.
    public let metadata: [String: Any]

    private init(
        name: DecisaEventName,
        value: Double? = nil,
        currency: String? = nil,
        customName: String? = nil,
        url: String? = nil,
        occurredAt: String? = nil,
        isTest: Bool = false,
        metadata: [String: Any] = [:],
        eventId: String? = nil
    ) {
        self.name = name
        self.value = value
        self.currency = currency
        self.customName = customName
        self.url = url
        self.occurredAt = occurredAt
        self.isTest = isTest
        self.metadata = metadata
        self.eventId = eventId ?? "evt_\(UUID().uuidString)"
    }

    // MARK: - Named constructors

    public static func purchase(
        value: Double,
        currency: String,
        url: String? = nil,
        occurredAt: String? = nil,
        isTest: Bool = false,
        metadata: [String: Any] = [:]
    ) -> DecisaEvent {
        DecisaEvent(
            name: .purchase,
            value: value,
            currency: currency,
            url: url,
            occurredAt: occurredAt,
            isTest: isTest,
            metadata: metadata
        )
    }

    public static func lead(
        value: Double? = nil,
        currency: String? = nil,
        url: String? = nil,
        occurredAt: String? = nil,
        isTest: Bool = false,
        metadata: [String: Any] = [:]
    ) -> DecisaEvent {
        DecisaEvent(
            name: .lead,
            value: value,
            currency: currency,
            url: url,
            occurredAt: occurredAt,
            isTest: isTest,
            metadata: metadata
        )
    }

    public static func completeRegistration(
        url: String? = nil,
        occurredAt: String? = nil,
        isTest: Bool = false,
        metadata: [String: Any] = [:]
    ) -> DecisaEvent {
        DecisaEvent(
            name: .completeRegistration,
            url: url,
            occurredAt: occurredAt,
            isTest: isTest,
            metadata: metadata
        )
    }

    public static func startTrial(
        value: Double? = nil,
        currency: String? = nil,
        url: String? = nil,
        occurredAt: String? = nil,
        isTest: Bool = false,
        metadata: [String: Any] = [:]
    ) -> DecisaEvent {
        DecisaEvent(
            name: .startTrial,
            value: value,
            currency: currency,
            url: url,
            occurredAt: occurredAt,
            isTest: isTest,
            metadata: metadata
        )
    }

    public static func subscribe(
        value: Double? = nil,
        currency: String? = nil,
        url: String? = nil,
        occurredAt: String? = nil,
        isTest: Bool = false,
        metadata: [String: Any] = [:]
    ) -> DecisaEvent {
        DecisaEvent(
            name: .subscribe,
            value: value,
            currency: currency,
            url: url,
            occurredAt: occurredAt,
            isTest: isTest,
            metadata: metadata
        )
    }

    public static func addToCart(
        value: Double? = nil,
        currency: String? = nil,
        url: String? = nil,
        occurredAt: String? = nil,
        isTest: Bool = false,
        metadata: [String: Any] = [:]
    ) -> DecisaEvent {
        DecisaEvent(
            name: .addToCart,
            value: value,
            currency: currency,
            url: url,
            occurredAt: occurredAt,
            isTest: isTest,
            metadata: metadata
        )
    }

    public static func initiateCheckout(
        value: Double? = nil,
        currency: String? = nil,
        url: String? = nil,
        occurredAt: String? = nil,
        isTest: Bool = false,
        metadata: [String: Any] = [:]
    ) -> DecisaEvent {
        DecisaEvent(
            name: .initiateCheckout,
            value: value,
            currency: currency,
            url: url,
            occurredAt: occurredAt,
            isTest: isTest,
            metadata: metadata
        )
    }

    public static func addPaymentInfo(
        url: String? = nil,
        occurredAt: String? = nil,
        isTest: Bool = false,
        metadata: [String: Any] = [:]
    ) -> DecisaEvent {
        DecisaEvent(
            name: .addPaymentInfo,
            url: url,
            occurredAt: occurredAt,
            isTest: isTest,
            metadata: metadata
        )
    }

    public static func viewContent(
        url: String? = nil,
        occurredAt: String? = nil,
        isTest: Bool = false,
        metadata: [String: Any] = [:]
    ) -> DecisaEvent {
        DecisaEvent(
            name: .viewContent,
            url: url,
            occurredAt: occurredAt,
            isTest: isTest,
            metadata: metadata
        )
    }

    public static func pageView(
        url: String? = nil,
        occurredAt: String? = nil,
        isTest: Bool = false,
        metadata: [String: Any] = [:]
    ) -> DecisaEvent {
        DecisaEvent(
            name: .pageView,
            url: url,
            occurredAt: occurredAt,
            isTest: isTest,
            metadata: metadata
        )
    }

    public static func search(
        url: String? = nil,
        occurredAt: String? = nil,
        isTest: Bool = false,
        metadata: [String: Any] = [:]
    ) -> DecisaEvent {
        DecisaEvent(
            name: .search,
            url: url,
            occurredAt: occurredAt,
            isTest: isTest,
            metadata: metadata
        )
    }

    public static func appInstall(
        occurredAt: String? = nil,
        isTest: Bool = false,
        metadata: [String: Any] = [:]
    ) -> DecisaEvent {
        DecisaEvent(
            name: .appInstall,
            occurredAt: occurredAt,
            isTest: isTest,
            metadata: metadata
        )
    }

    public static func custom(
        _ name: String,
        value: Double? = nil,
        currency: String? = nil,
        url: String? = nil,
        occurredAt: String? = nil,
        isTest: Bool = false,
        metadata: [String: Any] = [:]
    ) -> DecisaEvent {
        DecisaEvent(
            name: .custom,
            value: value,
            currency: currency,
            customName: name,
            url: url,
            occurredAt: occurredAt,
            isTest: isTest,
            metadata: metadata
        )
    }

    /// Builds the JSON body for `POST /v1/track`.
    func toTrackBody(
        visitorId: String,
        pixelKey: String,
        extraMetadata: [String: Any] = [:]
    ) -> [String: Any] {
        var mergedMetadata = extraMetadata
        for (key, value) in metadata {
            mergedMetadata[key] = value
        }
        if let customName {
            mergedMetadata["custom_event_name"] = customName
        }

        var body: [String: Any] = [
            "event_id": eventId,
            "event_name": name.wireName,
            "visitor_id": visitorId,
            "pixel_key": pixelKey,
            "is_test": isTest,
            "metadata": mergedMetadata,
        ]
        if let value { body["value"] = value }
        if let currency { body["currency"] = currency }
        if let url { body["url"] = url }
        if let occurredAt { body["occurred_at"] = occurredAt }
        return body
    }
}
