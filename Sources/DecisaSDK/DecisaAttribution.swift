// Copyright (c) Decisa. MIT licensed. See LICENSE.

import Foundation

/// The deferred-attribution result the SDK resolved (or fell back to) on first
/// launch and persisted for the install's lifetime.
public struct DecisaAttribution: Codable, Sendable, Equatable {
    /// The visitor id this install is bound to. Always present — even when the
    /// install did not match a click, the SDK mints a local fallback id.
    public let visitorId: String

    /// Whether the backend matched this install to a server-minted click.
    public let matched: Bool

    /// How the backend matched (e.g. `mclid`, `ip`). Nil when unmatched.
    public let matchType: String?

    public let utmSource: String?
    public let utmMedium: String?
    public let utmCampaign: String?
    public let utmContent: String?
    public let utmTerm: String?

    enum CodingKeys: String, CodingKey {
        case visitorId = "visitor_id"
        case matched
        case matchType = "match_type"
        case utmSource = "utm_source"
        case utmMedium = "utm_medium"
        case utmCampaign = "utm_campaign"
        case utmContent = "utm_content"
        case utmTerm = "utm_term"
    }

    public init(
        visitorId: String,
        matched: Bool,
        matchType: String? = nil,
        utmSource: String? = nil,
        utmMedium: String? = nil,
        utmCampaign: String? = nil,
        utmContent: String? = nil,
        utmTerm: String? = nil
    ) {
        self.visitorId = visitorId
        self.matched = matched
        self.matchType = matchType
        self.utmSource = utmSource
        self.utmMedium = utmMedium
        self.utmCampaign = utmCampaign
        self.utmContent = utmContent
        self.utmTerm = utmTerm
    }

    /// Builds an attribution from a `POST /v1/resolve` `data` object.
    static func fromResolveData(
        _ data: [String: Any],
        fallbackVisitorId: String
    ) -> DecisaAttribution {
        let rawVisitorId = (data["visitor_id"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let visitorId = (rawVisitorId?.isEmpty == false) ? rawVisitorId! : fallbackVisitorId

        return DecisaAttribution(
            visitorId: visitorId,
            matched: data["matched"] as? Bool ?? false,
            matchType: data["match_type"] as? String,
            utmSource: data["utm_source"] as? String,
            utmMedium: data["utm_medium"] as? String,
            utmCampaign: data["utm_campaign"] as? String,
            utmContent: data["utm_content"] as? String,
            utmTerm: data["utm_term"] as? String
        )
    }

    /// An unmatched attribution bound to a locally-generated fallback visitor id.
    static func unmatched(_ fallbackVisitorId: String) -> DecisaAttribution {
        DecisaAttribution(visitorId: fallbackVisitorId, matched: false)
    }

    /// The UTM fields as a compact map, omitting nils.
    func utmMap() -> [String: Any] {
        var map: [String: Any] = [:]
        if let utmSource { map["utm_source"] = utmSource }
        if let utmMedium { map["utm_medium"] = utmMedium }
        if let utmCampaign { map["utm_campaign"] = utmCampaign }
        if let utmContent { map["utm_content"] = utmContent }
        if let utmTerm { map["utm_term"] = utmTerm }
        return map
    }
}
