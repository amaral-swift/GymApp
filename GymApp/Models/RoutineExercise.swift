import Foundation
import SwiftData

@Model
final class RoutineExercise: Identifiable {
    @Attribute(.unique) var id: UUID
    var routineDay: RoutineDay?
    var exercise: Exercise?
    var position: Int
    var targetSets: Int?
    var targetRepsMin: Int?
    var targetRepsMax: Int?
    var targetRestSeconds: Int?
    var notes: String?
    var createdAt: Date
    var needsSync: Bool

    init(
        id: UUID = UUID(),
        routineDay: RoutineDay? = nil,
        exercise: Exercise? = nil,
        position: Int = 0,
        targetSets: Int? = nil,
        targetRepsMin: Int? = nil,
        targetRepsMax: Int? = nil,
        targetRestSeconds: Int? = nil,
        notes: String? = nil,
        createdAt: Date = .now,
        needsSync: Bool = true
    ) {
        self.id = id
        self.routineDay = routineDay
        self.exercise = exercise
        self.position = position
        self.targetSets = targetSets
        self.targetRepsMin = targetRepsMin
        self.targetRepsMax = targetRepsMax
        self.targetRestSeconds = targetRestSeconds
        self.notes = notes
        self.createdAt = createdAt
        self.needsSync = needsSync
    }

    var repsRangeLabel: String {
        guard let lo = targetRepsMin else { return "" }
        if let hi = targetRepsMax, hi != lo { return "\(lo)-\(hi)" }
        return "\(lo)"
    }
}
