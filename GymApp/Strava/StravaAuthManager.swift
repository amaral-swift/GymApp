import Foundation
import AuthenticationServices
import Combine
import UIKit

/// Cuida do login OAuth com o Strava (via ASWebAuthenticationSession) e guarda os tokens no Keychain.
@MainActor
final class StravaAuthManager: NSObject, ObservableObject {
    @Published var isConnected: Bool = false
    @Published var lastError: String?

    private var accessToken: String?
    private var refreshToken: String?
    private var expiresAt: Date?

    private let accessTokenKey = "strava_accessToken"
    private let refreshTokenKey = "strava_refreshToken"
    private let expiresAtKey = "strava_expiresAt"

    private var authSession: ASWebAuthenticationSession?

    override init() {
        super.init()
        restore()
    }

    private func restore() {
        guard
            let token = KeychainHelper.read(accessTokenKey),
            let refresh = KeychainHelper.read(refreshTokenKey)
        else { return }
        accessToken = token
        refreshToken = refresh
        if let expiresAtString = KeychainHelper.read(expiresAtKey), let seconds = TimeInterval(expiresAtString) {
            expiresAt = Date(timeIntervalSince1970: seconds)
        }
        isConnected = true
    }

    func connect() {
        lastError = nil
        guard StravaConfig.isConfigured else {
            lastError = "Configure o Client ID/Secret do Strava em StravaConfig.swift primeiro."
            return
        }
        let session = ASWebAuthenticationSession(
            url: StravaConfig.authorizeURL,
            callbackURLScheme: StravaConfig.callbackScheme
        ) { [weak self] callbackURL, error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    let nsError = error as NSError
                    if nsError.code != ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        self.lastError = "Falha ao conectar com o Strava."
                    }
                    return
                }
                guard
                    let callbackURL,
                    let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                    let code = components.queryItems?.first(where: { $0.name == "code" })?.value
                else {
                    self.lastError = "Não recebi o código de autorização do Strava."
                    return
                }
                await self.exchangeCode(code)
            }
        }
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        authSession = session
        session.start()
    }

    func disconnect() {
        accessToken = nil
        refreshToken = nil
        expiresAt = nil
        [accessTokenKey, refreshTokenKey, expiresAtKey].forEach(KeychainHelper.delete)
        isConnected = false
    }

    private func exchangeCode(_ code: String) async {
        await requestToken(body: [
            "client_id": StravaConfig.clientId,
            "client_secret": StravaConfig.clientSecret,
            "code": code,
            "grant_type": "authorization_code",
        ])
    }

    /// Garante um access token válido, renovando com o refresh token quando necessário.
    func validAccessToken() async -> String? {
        guard let accessToken else { return nil }
        if let expiresAt, expiresAt.timeIntervalSinceNow > 120 {
            return accessToken
        }
        guard let refreshToken else { return accessToken }
        await requestToken(body: [
            "client_id": StravaConfig.clientId,
            "client_secret": StravaConfig.clientSecret,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token",
        ])
        return self.accessToken
    }

    private func requestToken(body: [String: String]) async {
        var request = URLRequest(url: URL(string: "https://www.strava.com/oauth/token")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                lastError = "Strava recusou a conexão — confira o Client ID/Secret."
                return
            }
            let decoded = try JSONDecoder().decode(StravaTokenResponse.self, from: data)
            persist(decoded)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func persist(_ token: StravaTokenResponse) {
        accessToken = token.accessToken
        refreshToken = token.refreshToken
        expiresAt = Date(timeIntervalSince1970: TimeInterval(token.expiresAt))
        KeychainHelper.save(token.accessToken, forKey: accessTokenKey)
        KeychainHelper.save(token.refreshToken, forKey: refreshTokenKey)
        KeychainHelper.save(String(token.expiresAt), forKey: expiresAtKey)
        isConnected = true
    }
}

extension StravaAuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                for window in windowScene.windows where window.isKeyWindow {
                    return window
                }
            }
        }
        return ASPresentationAnchor()
    }
}

struct StravaTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
    }
}
