import Foundation

/// Credenciais do app registrado em https://www.strava.com/settings/api
/// Preencha clientId e clientSecret depois de criar o app por lá (veja instruções do Claude).
enum StravaConfig {
    static let clientId = "SEU_CLIENT_ID_AQUI"
    static let clientSecret = "SEU_CLIENT_SECRET_AQUI"

    /// Precisa bater com a URL scheme registrada em Target > Info > URL Types.
    static let callbackScheme = "gymapp"
    static let redirectURI = "gymapp://localhost/strava-callback"
    static let scope = "activity:read_all"

    static var isConfigured: Bool {
        clientId != "SEU_CLIENT_ID_AQUI" && !clientId.isEmpty && !clientSecret.isEmpty
    }

    static var authorizeURL: URL {
        var components = URLComponents(string: "https://www.strava.com/oauth/mobile/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "approval_prompt", value: "auto"),
            URLQueryItem(name: "scope", value: scope),
        ]
        return components.url!
    }
}
