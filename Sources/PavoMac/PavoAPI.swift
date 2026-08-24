import Foundation

/// Thin client for the Pavo Mac HTTP contract. Packer lives in Python.
public struct PavoAPI: Sendable {
    public var baseURL: URL

    public init(baseURL: URL) {
        self.baseURL = baseURL
    }

    public func files() async throws -> Data {
        try await get("api/files")
    }

    public func status() async throws -> Data {
        try await get("api/status")
    }

    public func ingest(id: String, kind: String? = nil, tags: [String] = [], force: Bool = false) async throws -> Data {
        var body: [String: Any] = ["id": id, "tags": tags, "force": force]
        if let kind { body["kind"] = kind }
        return try await post("api/ingest", body: body)
    }

    public func sync(force: Bool = false) async throws -> Data {
        try await post("api/sync?force=\(force)", body: [:])
    }

    private func get(_ path: String) async throws -> Data {
        let url = baseURL.appendingPathComponent(path)
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }

    private func post(_ path: String, body: [String: Any]) async throws -> Data {
        let url = baseURL.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return data
    }
}
