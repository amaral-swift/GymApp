import Foundation
import SwiftData

@Model
final class WorkoutSession: Identifiable {
    @Attribute(.unique) var id: UUID
    var routineDay: RoutineDay?
    var sessionDate: Date
    var startedAt: Date?
    var finishedAt: Date?
    var cardioMinutes: Int?
    var cardioType: String?
    var notes: String?
    /// Preenchido quando essa sessão veio de uma atividade importada do Strava (evita duplicar).
    var stravaActivityId: Int64?
    var createdAt: Date
    var needsSync: Bool

    @Relationship(deleteRule: .cascade, inverse: \LoggedSet.session)
    var loggedSets: [LoggedSet] = []

    init(
        id: UUID = UUID(),
        routineDay: RoutineDay? = nil,
        sessionDate: Date = .now,
        startedAt: Date? = nil,
        finishedAt: Date? = nil,
        cardioMinutes: Int? = nil,
        cardioType: String? = nil,
        notes: String? = nil,
        stravaActivityId: Int64? = nil,
        createdAt: Date = .now,
        needsSync: Bool = true
    ) {
        self.id = id
        self.routineDay = routineDay
        self.sessionDate = sessionDate
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.cardioMinutes = cardioMinutes
        self.cardioType = cardioType
        self.notes = notes
        self.stravaActivityId = stravaActivityId
        self.createdAt = createdAt
        self.needsSync = needsSync
    }
}
