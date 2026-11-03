import Foundation
import SwiftUI

/// Cuida do login/cadastro no Supabase (via GoTrue) e guarda a sessão no Keychain.
@MainActor
final class SupabaseAuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUserId: UUID?
    @Published var lastError: String?

    private var accessToken: String?
    private var refreshToken: String?
    private var expiresAt: Date?

    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    private let userIdKey = "userId"
    private let expiresAtKey = "expiresAt"

    init() {
        restoreSession()
    }

    private func restoreSession() {
        guard
            let token = KeychainHelper.read(accessTokenKey),
            let refresh = KeychainHelper.read(refreshTokenKey),
            let userIdString = KeychainHelper.read(userIdKey),
            let userId = UUID(uuidString: userIdString)
        else { return }
        accessToken = token
        refreshToken = refresh
        currentUserId = userId
        if let expiresAtString = KeychainHelper.read(expiresAtKey), let seconds = TimeInterval(expiresAtString) {
            expiresAt = Date(timeIntervalSince1970: seconds)
        }
        isAuthenticated = true
    }

    private func persistSession(_ auth: AuthTokenResponse) {
        accessToken = auth.accessToken
        refreshToken = auth.refreshToken
        currentUserId = UUID(uuidString: auth.user.id)
        let expiry = Date().addingTimeInterval(TimeInterval(auth.expiresIn))
        expiresAt = expiry

        KeychainHelper.save(auth.accessToken, forKey: accessTokenKey)
        KeychainHelper.save(auth.refreshToken, forKey: refreshTokenKey)
        KeychainHelper.save(auth.user.id, forKey: userIdKey)
        KeychainHelper.save(String(expiry.timeIntervalSince1970), forKey: expiresAtKey)
        isAuthenticated = true
    }

    func signOut() {
        accessToken = nil
        refreshToken = nil
        currentUserId = nil
        expiresAt = nil
        [accessTokenKey, refreshTokenKey, userIdKey, expiresAtKey].forEach(KeychainHelper.delete)
        isAuthenticated = false
    }

    func signUp(email: String, password: String) async {
        await performAuthRequest(path: "signup", email: email, password: password)
    }

    func signIn(email: String, password: String) async {
        await performAuthRequest(path: "token?grant_type=password", email: email, password: password)
    }

    private func performAuthRequest(path: String, email: String, password: String) async {
        lastError = nil
        var request = URLRequest(url: SupabaseConfig.authURL.appendingPathComponent(path))
        if path.hasPrefix("token") {
            request = URLRequest(url: URL(string: SupabaseConfig.authURL.absoluteString + "/" + path)!)
        }
        request.httpMethod = "POST"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["email": email, "password": password])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return }
            if http.statusCode >= 200 && http.statusCode < 300 {
                let auth = try JSONDecoder().decode(AuthTokenResponse.self, from: data)
                persistSession(auth)
            } else {
                let message = (try? JSONDecoder().decode(AuthErrorResponse.self, from: data))?.errorDescription
                lastError = message ?? "Falha no login (HTTP \(http.statusCode))"
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Garante um access token válido, renovando com o refresh token se estiver perto de expirar.
    func validAccessToken() async -> String? {
        guard let accessToken else { return nil }
        if let expiresAt, expiresAt.timeIntervalSinceNow > 60 {
            return accessToken
        }
        guard let refreshToken else { return accessToken }

        var request = URLRequest(url: URL(string: SupabaseConfig.authURL.absoluteString + "/token?grant_type=refresh_token")!)
        request.httpMethod = "POST"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["refresh_token": refreshToken])

        guard
            let (data, response) = try? await URLSession.shared.data(for: request),
            let http = response as? HTTPURLResponse,
            http.statusCode == 200,
            let auth = try? JSONDecoder().decode(AuthTokenResponse.self, from: data)
        else {
            return accessToken
        }
        persistSession(auth)
        return auth.accessToken
    }
}

struct AuthTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let user: AuthUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case user
    }
}

struct AuthUser: Decodable {
    let id: String
}

struct AuthErrorResponse: Decodable {
    let errorDescription: String?

    enum CodingKeys: String, CodingKey {
        case errorDescription = "error_description"
        case msg
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let desc = try container.decodeIfPresent(String.self, forKey: .errorDescription) {
            errorDescription = desc
        } else {
            errorDescription = try container.decodeIfPresent(String.self, forKey: .msg)
        }
    }
}
