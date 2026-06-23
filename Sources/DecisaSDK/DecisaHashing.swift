// Copyright (c) Decisa. MIT licensed. See LICENSE.

import CryptoKit
import Foundation

/// Client-side identity hashing for `/v1/identify`.
///
/// Raw PII (email, phone) must NEVER leave the device.
enum DecisaHashing {
    /// Normalizes (lowercase + trim) and SHA-256-hashes an email.
    static func email(_ raw: String?) -> String? {
        guard let normalized = normalize(raw) else { return nil }
        return sha256Hex(normalized)
    }

    /// Normalizes and SHA-256-hashes a phone number.
    static func phone(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let stripped = raw.replacingOccurrences(
            of: "[^0-9+]",
            with: "",
            options: .regularExpression
        )
        guard let normalized = normalize(stripped) else { return nil }
        return sha256Hex(normalized)
    }

    /// Normalizes (lowercase + trim) and SHA-256-hashes free text (name).
    static func text(_ raw: String?) -> String? {
        guard let normalized = normalize(raw) else { return nil }
        return sha256Hex(normalized)
    }

    private static func normalize(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return value.isEmpty ? nil : value
    }

    private static func sha256Hex(_ value: String) -> String {
        let digest = SHA256.hash(data: Data(value.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
