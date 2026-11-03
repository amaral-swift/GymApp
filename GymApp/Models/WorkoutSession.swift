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
        self.createdAt = createdAt
        self.needsSync = needsSync
    }
}
