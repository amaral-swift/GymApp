import Foundation
import SwiftData

@Model
final class LoggedSet: Identifiable {
    @Attribute(.unique) var id: UUID
    var session: WorkoutSession?
    var exercise: Exercise?
    var setNumber: Int
    var reps: Int?
    var weightKg: Double?
    var rpe: Double?
    var notes: String?
    var createdAt: Date
    var needsSync: Bool

    init(
        id: UUID = UUID(),
        session: WorkoutSession? = nil,
        exercise: Exercise? = nil,
        setNumber: Int,
        reps: Int? = nil,
        weightKg: Double? = nil,
        rpe: Double? = nil,
        notes: String? = nil,
        createdAt: Date = .now,
        needsSync: Bool = true
    ) {
        self.id = id
        self.session = session
        self.exercise = exercise
        self.setNumber = setNumber
        self.reps = reps
        self.weightKg = weightKg
        self.rpe = rpe
        self.notes = notes
        self.createdAt = createdAt
        self.needsSync = needsSync
    }
}
