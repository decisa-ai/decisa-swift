// Copyright (c) Decisa. MIT licensed. See LICENSE.

import Foundation

/// Outcome of a transport call.
struct DecisaResponse {
    let statusCode: Int
    let data: [String: Any]?
    let error: [String: Any]?

    /// 2xx — accepted/ok. 204 included (silent success with no body).
    var isSuccess: Bool { (200 ..< 300).contains(statusCode) }

    /// 204 No Content — used by `/resolve` for an unknown pixel key.
    var isNoContent: Bool { statusCode == 204 }

    static let networkFailure = DecisaResponse(statusCode: 0, data: nil, error: nil)
}

/// Thin HTTP transport for the three public ingest endpoints.
protocol DecisaTransporting: Sendable {
    func post(path: String, body: [String: Any]) async -> DecisaResponse
}

final class DecisaTransport: DecisaTransporting, @unchecked Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let timeout: TimeInterval

    private static let headers: [String: String] = [
        "Content-Type": "application/json",
        "Accept": "application/json",
    ]

    init(baseURL: URL, session: URLSession = .shared, timeout: TimeInterval = 10) {
        var trimmed = baseURL.absoluteString
        if trimmed.hasSuffix("/") {
            trimmed.removeLast()
        }
        self.baseURL = URL(string: trimmed)!
        self.session = session
        self.timeout = timeout
    }

    func post(path: String, body: [String: Any]) async -> DecisaResponse {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            return .networkFailure
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        for (key, value) in Self.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            return try await withCheckedThrowingContinuation { continuation in
                let task = session.dataTask(with: request) { data, response, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.resume(returning: .networkFailure)
                        return
                    }
                    let statusCode = httpResponse.statusCode
                    let responseData = data ?? Data()
                    if statusCode == 204 || responseData.isEmpty {
                        continuation.resume(
                            returning: DecisaResponse(statusCode: statusCode, data: nil, error: nil)
                        )
                        return
                    }
                    guard let decoded = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any] else {
                        continuation.resume(
                            returning: DecisaResponse(statusCode: statusCode, data: nil, error: nil)
                        )
                        return
                    }
                    let envelopeData = decoded["data"] as? [String: Any]
                    let envelopeError = decoded["error"] as? [String: Any]
                    continuation.resume(
                        returning: DecisaResponse(
                            statusCode: statusCode,
                            data: envelopeData,
                            error: envelopeError
                        )
                    )
                }
                task.resume()
            }
        } catch {
            return .networkFailure
        }
    }
}
