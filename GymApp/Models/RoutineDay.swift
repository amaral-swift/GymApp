import Foundation
import SwiftData

enum RoutineKind: String, Codable, CaseIterable {
    case lifting
    case cardio
    case rest

    var label: String {
        switch self {
        case .lifting: return "Musculação"
        case .cardio: return "Cardio"
        case .rest: return "Descanso"
        }
    }
}

/// weekday: 1 = segunda ... 7 = domingo (ISO-8601)
@Model
final class RoutineDay: Identifiable {
    @Attribute(.unique) var id: UUID
    var weekday: Int
    var name: String
    var kindRaw: String
    var cardioType: String?
    var cardioMinutesMin: Int?
    var cardioMinutesMax: Int?
    var notes: String?
    var position: Int
    var createdAt: Date
    var needsSync: Bool

    @Relationship(deleteRule: .cascade, inverse: \RoutineExercise.routineDay)
    var exercises: [RoutineExercise] = []

    var kind: RoutineKind {
        get { RoutineKind(rawValue: kindRaw) ?? .rest }
        set { kindRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        weekday: Int,
        name: String,
        kind: RoutineKind,
        cardioType: String? = nil,
        cardioMinutesMin: Int? = nil,
        cardioMinutesMax: Int? = nil,
        notes: String? = nil,
        position: Int = 0,
        createdAt: Date = .now,
        needsSync: Bool = true
    ) {
        self.id = id
        self.weekday = weekday
        self.name = name
        self.kindRaw = kind.rawValue
        self.cardioType = cardioType
        self.cardioMinutesMin = cardioMinutesMin
        self.cardioMinutesMax = cardioMinutesMax
        self.notes = notes
        self.position = position
        self.createdAt = createdAt
        self.needsSync = needsSync
    }

    static let weekdayNames = ["", "Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado", "Domingo"]
}
