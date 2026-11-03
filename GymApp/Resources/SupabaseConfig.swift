import Foundation

/// Credenciais do projeto Supabase do GymApp.
/// A anon key é pública por design (protegida pelas políticas de RLS no banco),
/// então é seguro mantê-la embutida no app.
enum SupabaseConfig {
    static let url = URL(string: "https://mospgkaovcnshbgidrwg.supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vc3Bna2FvdmNuc2hiZ2lkcndnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM2NzkzODcsImV4cCI6MjEwOTI1NTM4N30.E8KomdDAngRfbJjkz315AwcnGGYFdT9QPWPckKoGlIM"

    static var restURL: URL { url.appendingPathComponent("rest/v1") }
    static var authURL: URL { url.appendingPathComponent("auth/v1") }
}
