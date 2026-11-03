import Foundation
import SwiftData

@Model
final class Exercise: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var muscleGroup: String?
    var notes: String?
    var createdAt: Date
    var needsSync: Bool

    init(
        id: UUID = UUID(),
        name: String,
        muscleGroup: String? = nil,
        notes: String? = nil,
        createdAt: Date = .now,
        needsSync: Bool = true
    ) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.notes = notes
        self.createdAt = createdAt
        self.needsSync = needsSync
    }
}
