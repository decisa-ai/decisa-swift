// Copyright (c) Decisa. MIT licensed. See LICENSE.

import Foundation

/// The canonical, Meta-standard pixel event names accepted by `POST /v1/track`.
///
/// Mirrors the backend `PixelEventName` enum exactly. The string [wireName] is
/// what the SDK sends as `event_name`.
public enum DecisaEventName: String, Sendable {
    case pageView = "PageView"
    case viewContent = "ViewContent"
    case search = "Search"
    case addToCart = "AddToCart"
    case addPaymentInfo = "AddPaymentInfo"
    case initiateCheckout = "InitiateCheckout"
    case lead = "Lead"
    case completeRegistration = "CompleteRegistration"
    case purchase = "Purchase"
    case startTrial = "StartTrial"
    case subscribe = "Subscribe"
    case appInstall = "AppInstall"
    case custom = "Custom"

    /// The exact `event_name` string the backend expects.
    public var wireName: String { rawValue }
}
