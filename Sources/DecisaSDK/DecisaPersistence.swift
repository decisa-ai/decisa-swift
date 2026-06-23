// Copyright (c) Decisa. MIT licensed. See LICENSE.

import Foundation

/// Device-local persistence for the resolved attribution and identity.
protocol DecisaPersisting: Sendable {
    func hasResolved() -> Bool
    func saveAttribution(_ attribution: DecisaAttribution) throws
    func readAttribution() -> DecisaAttribution?
    func saveExternalId(_ externalId: String) throws
    func readExternalId() -> String?
    func clear() throws
}

final class DecisaPersistence: DecisaPersisting, @unchecked Sendable {
    private static let attributionKey = "decisa.attribution"
    private static let externalIdKey = "decisa.external_id"
    private static let resolvedKey = "decisa.resolved"

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func hasResolved() -> Bool {
        defaults.bool(forKey: Self.resolvedKey)
    }

    func saveAttribution(_ attribution: DecisaAttribution) throws {
        let data = try encoder.encode(attribution)
        guard let json = String(data: data, encoding: .utf8) else {
            throw PersistenceError.encodingFailed
        }
        defaults.set(json, forKey: Self.attributionKey)
        defaults.set(true, forKey: Self.resolvedKey)
    }

    func readAttribution() -> DecisaAttribution? {
        guard let raw = defaults.string(forKey: Self.attributionKey), !raw.isEmpty else {
            return nil
        }
        guard let data = raw.data(using: .utf8) else { return nil }
        return try? decoder.decode(DecisaAttribution.self, from: data)
    }

    func saveExternalId(_ externalId: String) throws {
        defaults.set(externalId, forKey: Self.externalIdKey)
    }

    func readExternalId() -> String? {
        defaults.string(forKey: Self.externalIdKey)
    }

    func clear() throws {
        defaults.removeObject(forKey: Self.attributionKey)
        defaults.removeObject(forKey: Self.externalIdKey)
        defaults.removeObject(forKey: Self.resolvedKey)
    }

    enum PersistenceError: Error {
        case encodingFailed
    }
}
