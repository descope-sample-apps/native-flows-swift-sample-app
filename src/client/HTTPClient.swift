
import Foundation

class HTTPClient {
    let baseURL: String

    init(baseURL: String) {
        self.baseURL = baseURL
    }

    // Convenience response functions

    final func get<T: JSONResponse>(_ route: String, headers: [String: String] = [:], params: [String: String?] = [:]) async throws -> T {
        let (data, response) = try await get(route, headers: headers, params: params)
        return try decodeJSON(data: data, response: response)
    }

    final func post<T: JSONResponse>(_ route: String, headers: [String: String] = [:], params: [String: String?] = [:], body: [String: Any?] = [:]) async throws -> T {
        let (data, response) = try await post(route, headers: headers, params: params, body: body)
        return try decodeJSON(data: data, response: response)
    }

    // Convenience data functions

    @discardableResult
    final func get(_ route: String, headers: [String: String] = [:], params: [String: String?] = [:]) async throws -> (Data, HTTPURLResponse) {
        return try await call(route, method: "GET", headers: headers, params: params, body: nil)
    }

    @discardableResult
    final func post(_ route: String, headers: [String: String] = [:], params: [String: String?] = [:], body: [String: Any?] = [:]) async throws -> (Data, HTTPURLResponse) {
        return try await call(route, method: "POST", headers: headers, params: params, body: encodeJSON(body))
    }

    // Override points

    var basePath: String {
        return "/"
    }

    var defaultHeaders: [String: String] {
        return [:]
    }

    var defaultTimeout: TimeInterval {
        return 15
    }

    // Private

    private let networkClient = DefaultNetworkClient()

    private func call(_ route: String, method: String, headers: [String: String], params: [String: String?], body: Data?) async throws -> (Data, HTTPURLResponse) {
        let request = try makeRequest(route: route, method: method, headers: headers, params: params, body: body)

        let (data, response) = try await sendRequest(request)

        guard let response = response as? HTTPURLResponse else { throw HTTPError(message: "Invalid reponse") }

        if response.statusCode != 200 {
            throw HTTPError(message: "Invalid status code \(response.statusCode)")
        }

        return (data, response)
    }

    private func makeRequest(route: String, method: String, headers: [String: String], params: [String: String?], body: Data?) throws -> URLRequest {
        let url = try makeURL(route: route, params: params)
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: defaultTimeout)
        request.httpMethod = method
        request.httpBody = body
        for (key, value) in mergeHeaders(headers, with: defaultHeaders, for: request) {
            request.setValue(value, forHTTPHeaderField: key)
        }
        return request
    }

    private func makeURL(route: String, params: [String: String?]) throws -> URL {
        guard var url = URL(string: baseURL) else { throw HTTPError(message: "Invalid route") }
        url.appendPathComponent(basePath, isDirectory: false)
        url.appendPathComponent(route, isDirectory: false)
        guard var components = URLComponents(string: url.absoluteString) else { throw HTTPError(message: "Invalid route") }
        if case let params = params.compacted(), !params.isEmpty {
            components.queryItems = params.map(URLQueryItem.init)
        }
        guard let url = components.url else { throw HTTPError(message: "Invalid route") }
        return url
    }

    private func sendRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        return try await networkClient.call(request: request)
    }
}

// JSON Response

protocol JSONResponse: Decodable {
    mutating func setValues(from data: Data, response: HTTPURLResponse) throws
}

extension JSONResponse {
    mutating func setValues(from data: Data, response: HTTPURLResponse) throws {
        // nothing by default
    }
}

private func decodeJSON<T: JSONResponse>(data: Data, response: HTTPURLResponse) throws -> T {
    var val = try JSONDecoder().decode(T.self, from: data)
    try val.setValues(from: data, response: response)
    return val
}

// JSON Request

private func encodeJSON(_ body: [String: Any?]) throws -> Data {
    let compact = body.compacted()
    let data = try JSONSerialization.data(withJSONObject: compact, options: [])
    return data
}

private extension Dictionary {
    func compacted<T>() -> Dictionary<Key, T> where Value == T? {
        return compactMapValues { value in
            if let dict = value as? Self {
                return dict.compacted() as? T
            }
            return value
        }
    }
}

// HTTP Headers

private func mergeHeaders(_ headers: [String: String], with defaults: [String: String], for request: URLRequest) -> [String: String] {
    var result = request.allHTTPHeaderFields ?? [:]
    if request.httpBody != nil {
        result["Content-Type"] = "application/json"
    }
    result.merge(defaults, uniquingKeysWith: { $1 })
    result.merge(headers, uniquingKeysWith: { $1 })
    return result
}

// Network

private class DefaultNetworkClient {
    private let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)

    deinit {
        session.finishTasksAndInvalidate()
    }

    func call(request: URLRequest) async throws -> (Data, URLResponse) {
        return try await session.data(for: request)
    }
}

struct HTTPError: Error {
    var message: String
}

extension HTTPError: LocalizedError {
    /// Returns a user friendly message describing what error occurred.
    public var errorDescription: String? {
        return message
    }
}
