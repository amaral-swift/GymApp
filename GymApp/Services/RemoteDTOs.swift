import Foundation

/// Structs "planas" que espelham as tabelas do Supabase, usadas só pra (de)serializar JSON.
/// owner_id nunca é enviado: o banco preenche sozinho via default auth.uid(), e as policies de RLS
/// garantem que cada usuário só vê/edita as próprias linhas.

struct RemoteExercise: Codable {
    let id: UUID
    let name: String
    let muscleGroup: String?
    let notes: String?
    let createdAt: Date
}

struct RemoteRoutineDay: Codable {
    let id: UUID
    let weekday: Int
    let name: String
    let kind: String
    let cardioType: String?
    let cardioMinutesMin: Int?
    let cardioMinutesMax: Int?
    let notes: String?
    let position: Int
    let createdAt: Date
}

struct RemoteRoutineExercise: Codable {
    let id: UUID
    let routineDayId: UUID
    let exerciseId: UUID
    let position: Int
    let targetSets: Int?
    let targetRepsMin: Int?
    let targetRepsMax: Int?
    let targetRestSeconds: Int?
    let notes: String?
    let createdAt: Date
}

struct RemoteWorkoutSession: Codable {
    let id: UUID
    let routineDayId: UUID?
    let sessionDate: String // yyyy-MM-dd, formatado à parte (ver SupabaseJSON.dateOnlyFormatter)
    let startedAt: Date?
    let finishedAt: Date?
    let cardioMinutes: Int?
    let cardioType: String?
    let notes: String?
    let createdAt: Date
}

struct RemoteLoggedSet: Codable {
    let id: UUID
    let sessionId: UUID
    let exerciseId: UUID
    let setNumber: Int
    let reps: Int?
    let weightKg: Double?
    let rpe: Double?
    let notes: String?
    let createdAt: Date
}
