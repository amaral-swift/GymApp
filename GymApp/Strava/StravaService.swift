import Foundation
import SwiftData

struct StravaActivity: Decodable {
    let id: Int64
    let type: String
    let startDateLocal: String
    let movingTime: Int
    let distance: Double
    let name: String

    enum CodingKeys: String, CodingKey {
        case id, type, name
        case startDateLocal = "start_date_local"
        case movingTime = "moving_time"
        case distance
    }
}

/// Busca atividades recentes do Strava e transforma as de corrida/pedal em WorkoutSession locais.
@MainActor
struct StravaService {
    let auth: StravaAuthManager

    private static let runTypes: Set<String> = ["Run", "TrailRun", "VirtualRun"]
    private static let rideTypes: Set<String> = ["Ride", "VirtualRide", "GravelRide", "MountainBikeRide", "EBikeRide"]

    func fetchRecentActivities(daysBack: Int = 30) async -> [StravaActivity] {
        guard let token = await auth.validAccessToken() else { return [] }
        let after = Int(Date().addingTimeInterval(-Double(daysBack * 86400)).timeIntervalSince1970)
        var components = URLComponents(string: "https://www.strava.com/api/v3/athlete/activities")!
        components.queryItems = [
            URLQueryItem(name: "after", value: String(after)),
            URLQueryItem(name: "per_page", value: "100"),
        ]
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        guard
            let (data, response) = try? await URLSession.shared.data(for: request),
            let http = response as? HTTPURLResponse, http.statusCode == 200
        else { return [] }
        return (try? JSONDecoder().decode([StravaActivity].self, from: data)) ?? []
    }

    /// Importa corridas e pedais recentes pro histórico local (marcados pra sincronizar com o Supabase).
    /// Não duplica: pula atividades cujo stravaActivityId já existe localmente.
    @discardableResult
    func importActivities(context: ModelContext, daysBack: Int = 30) async -> Int {
        let activities = await fetchRecentActivities(daysBack: daysBack)
        let relevant = activities.filter { Self.runTypes.contains($0.type) || Self.rideTypes.contains($0.type) }

        let existingIds = Set(((try? context.fetch(FetchDescriptor<WorkoutSession>())) ?? []).compactMap(\.stravaActivityId))

        var imported = 0
        for activity in relevant where !existingIds.contains(activity.id) {
            guard let date = Self.parseStravaLocalDate(activity.startDateLocal) else { continue }
            let cardioType = Self.rideTypes.contains(activity.type) ? "pedal" : "corrida"
            let km = activity.distance / 1000
            let session = WorkoutSession(
                routineDay: nil,
                sessionDate: date,
                startedAt: date,
                finishedAt: date.addingTimeInterval(Double(activity.movingTime)),
                cardioMinutes: activity.movingTime / 60,
                cardioType: cardioType,
                notes: "Importado do Strava: \(activity.name) · \(String(format: "%.1f", km)) km",
                stravaActivityId: activity.id
            )
            context.insert(session)
            imported += 1
        }
        try? context.save()
        return imported
    }

    /// O Strava manda start_date_local terminado em "Z" mesmo sendo hora local (não UTC de verdade).
    /// Aqui a gente lê os números "crus" e monta um Date que bate com o relógio local do aparelho.
    private static func parseStravaLocalDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let trimmed = string.hasSuffix("Z") ? String(string.dropLast()) : string
        guard let reading = formatter.date(from: trimmed) else { return nil }

        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        let components = utcCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: reading)

        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.timeZone = TimeZone.current
        return localCalendar.date(from: components)
    }
}
