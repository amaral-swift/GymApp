import Foundation

enum SupabaseRestError: LocalizedError {
    case notAuthenticated
    case server(Int, String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Sessão expirada, faça login novamente."
        case .server(let code, let message): return "Erro do servidor (\(code)): \(message)"
        }
    }
}

/// Cliente HTTP bem simples pra falar direto com o PostgREST do Supabase,
/// sem depender de nenhum SDK/Swift Package externo.
struct SupabaseRestClient {
    let auth: SupabaseAuthManager

    private func url(_ path: String) -> URL {
        URL(string: SupabaseConfig.restURL.absoluteString + "/" + path)!
    }

    private func makeRequest(path: String, method: String, token: String, body: Data? = nil, extraHeaders: [String: String] = [:]) -> URLRequest {
        var request = URLRequest(url: url(path))
        request.httpMethod = method
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (key, value) in extraHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = body
        return request
    }

    func select<T: Decodable>(_ table: String, query: String = "select=*") async throws -> [T] {
        guard let token = await auth.validAccessToken() else { throw SupabaseRestError.notAuthenticated }
        let request = makeRequest(path: "\(table)?\(query)", method: "GET", token: token)
        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.checkResponse(response, data: data)
        return try SupabaseJSON.decoder.decode([T].self, from: data)
    }

    @discardableResult
    func upsert(_ table: String, body: Data, onConflict: String = "id") async throws -> Data {
        guard let token = await auth.validAccessToken() else { throw SupabaseRestError.notAuthenticated }
        let request = makeRequest(
            path: "\(table)?on_conflict=\(onConflict)",
            method: "POST",
            token: token,
            body: body,
            extraHeaders: ["Prefer": "resolution=merge-duplicates,return=minimal"]
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.checkResponse(response, data: data)
        return data
    }

    func delete(_ table: String, id: UUID) async throws {
        guard let token = await auth.validAccessToken() else { throw SupabaseRestError.notAuthenticated }
        let request = makeRequest(path: "\(table)?id=eq.\(id.uuidString)", method: "DELETE", token: token)
        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.checkResponse(response, data: data)
    }

    private static func checkResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? ""
            throw SupabaseRestError.server(http.statusCode, message)
        }
    }
}
