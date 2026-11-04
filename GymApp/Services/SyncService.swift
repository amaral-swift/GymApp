import Foundation
import Combine
import SwiftData

/// Sincroniza os dados locais (SwiftData) com o Supabase.
/// Estratégia simples "push-through": tudo que muda localmente é marcado com needsSync = true
/// e empurrado pro Supabase na próxima sincronização; no pull, os dados do Supabase são
/// a fonte da verdade (é o que o Claude lê pra ajustar os próximos treinos).
@MainActor
final class SyncService: ObservableObject {
    private let auth: SupabaseAuthManager
    private let rest: SupabaseRestClient

    init(auth: SupabaseAuthManager) {
        self.auth = auth
        self.rest = SupabaseRestClient(auth: auth)
    }

    func sync(context: ModelContext) async {
        guard auth.isAuthenticated else { return }
        await pushAll(context: context)
        await pullAll(context: context)
    }

    // MARK: - Push

    private func pushAll(context: ModelContext) async {
        await pushExercises(context: context)
        await pushRoutineDays(context: context)
        await pushRoutineExercises(context: context)
        await pushSessions(context: context)
        await pushLoggedSets(context: context)
        try? context.save()
    }

    private func pushExercises(context: ModelContext) async {
        let items = (try? context.fetch(FetchDescriptor<Exercise>(predicate: #Predicate { $0.needsSync }))) ?? []
        for item in items {
            let dto = RemoteExercise(id: item.id, name: item.name, muscleGroup: item.muscleGroup, notes: item.notes, createdAt: item.createdAt)
            if await upsertRemote("exercises", dto) { item.needsSync = false }
        }
    }

    private func pushRoutineDays(context: ModelContext) async {
        let items = (try? context.fetch(FetchDescriptor<RoutineDay>(predicate: #Predicate { $0.needsSync }))) ?? []
        for item in items {
            let dto = RemoteRoutineDay(
                id: item.id, weekday: item.weekday, name: item.name, kind: item.kindRaw,
                cardioType: item.cardioType, cardioMinutesMin: item.cardioMinutesMin,
                cardioMinutesMax: item.cardioMinutesMax, notes: item.notes, position: item.position, createdAt: item.createdAt
            )
            if await upsertRemote("routine_days", dto) { item.needsSync = false }
        }
    }

    private func pushRoutineExercises(context: ModelContext) async {
        let items = (try? context.fetch(FetchDescriptor<RoutineExercise>(predicate: #Predicate { $0.needsSync }))) ?? []
        for item in items {
            guard let dayId = item.routineDay?.id, let exerciseId = item.exercise?.id else { continue }
            let dto = RemoteRoutineExercise(
                id: item.id, routineDayId: dayId, exerciseId: exerciseId, position: item.position,
                targetSets: item.targetSets, targetRepsMin: item.targetRepsMin, targetRepsMax: item.targetRepsMax,
                targetRestSeconds: item.targetRestSeconds, notes: item.notes, createdAt: item.createdAt
            )
            if await upsertRemote("routine_exercises", dto) { item.needsSync = false }
        }
    }

    private func pushSessions(context: ModelContext) async {
        let items = (try? context.fetch(FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.needsSync }))) ?? []
        for item in items {
            let dto = RemoteWorkoutSession(
                id: item.id, routineDayId: item.routineDay?.id,
                sessionDate: SupabaseJSON.dateOnlyFormatter.string(from: item.sessionDate),
                startedAt: item.startedAt, finishedAt: item.finishedAt,
                cardioMinutes: item.cardioMinutes, cardioType: item.cardioType,
                notes: item.notes, createdAt: item.createdAt
            )
            if await upsertRemote("workout_sessions", dto) { item.needsSync = false }
        }
    }

    private func pushLoggedSets(context: ModelContext) async {
        let items = (try? context.fetch(FetchDescriptor<LoggedSet>(predicate: #Predicate { $0.needsSync }))) ?? []
        for item in items {
            guard let sessionId = item.session?.id, let exerciseId = item.exercise?.id else { continue }
            let dto = RemoteLoggedSet(
                id: item.id, sessionId: sessionId, exerciseId: exerciseId, setNumber: item.setNumber,
                reps: item.reps, weightKg: item.weightKg, rpe: item.rpe, notes: item.notes, createdAt: item.createdAt
            )
            if await upsertRemote("logged_sets", dto) { item.needsSync = false }
        }
    }

    /// Apaga uma sessão de treino (e suas séries, por cascade) tanto no Supabase quanto localmente.
    /// Usado pra limpar sessões criadas por engano ou vazias no Histórico.
    func deleteSession(_ session: WorkoutSession, context: ModelContext) async {
        if auth.isAuthenticated {
            do {
                try await rest.delete("workout_sessions", id: session.id)
            } catch {
                print("Sync: falha ao apagar sessão remota: \(error)")
            }
        }
        context.delete(session)
        try? context.save()
    }

    private func upsertRemote<T: Encodable>(_ table: String, _ dto: T) async -> Bool {
        do {
            let body = try SupabaseJSON.encoder.encode(dto)
            try await rest.upsert(table, body: body)
            return true
        } catch {
            print("Sync: falha ao enviar pra \(table): \(error)")
            return false
        }
    }

    // MARK: - Pull

    private func pullAll(context: ModelContext) async {
        if let remote: [RemoteExercise] = try? await rest.select("exercises") {
            for r in remote { upsertLocalExercise(r, context: context) }
        }
        if let remote: [RemoteRoutineDay] = try? await rest.select("routine_days") {
            for r in remote { upsertLocalRoutineDay(r, context: context) }
        }
        if let remote: [RemoteRoutineExercise] = try? await rest.select("routine_exercises") {
            for r in remote { upsertLocalRoutineExercise(r, context: context) }
        }
        if let remote: [RemoteWorkoutSession] = try? await rest.select("workout_sessions") {
            for r in remote { upsertLocalSession(r, context: context) }
        }
        if let remote: [RemoteLoggedSet] = try? await rest.select("logged_sets") {
            for r in remote { upsertLocalLoggedSet(r, context: context) }
        }
        try? context.save()
    }

    private func findExercise(_ id: UUID, _ context: ModelContext) -> Exercise? {
        try? context.fetch(FetchDescriptor<Exercise>(predicate: #Predicate { $0.id == id })).first
    }

    private func findRoutineDay(_ id: UUID, _ context: ModelContext) -> RoutineDay? {
        try? context.fetch(FetchDescriptor<RoutineDay>(predicate: #Predicate { $0.id == id })).first
    }

    private func findSession(_ id: UUID, _ context: ModelContext) -> WorkoutSession? {
        try? context.fetch(FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.id == id })).first
    }

    private func upsertLocalExercise(_ r: RemoteExercise, context: ModelContext) {
        if let existing = findExercise(r.id, context) {
            existing.name = r.name; existing.muscleGroup = r.muscleGroup; existing.notes = r.notes; existing.needsSync = false
        } else {
            context.insert(Exercise(id: r.id, name: r.name, muscleGroup: r.muscleGroup, notes: r.notes, createdAt: r.createdAt, needsSync: false))
        }
    }

    private func upsertLocalRoutineDay(_ r: RemoteRoutineDay, context: ModelContext) {
        if let existing = findRoutineDay(r.id, context) {
            existing.weekday = r.weekday; existing.name = r.name; existing.kindRaw = r.kind
            existing.cardioType = r.cardioType; existing.cardioMinutesMin = r.cardioMinutesMin
            existing.cardioMinutesMax = r.cardioMinutesMax; existing.notes = r.notes; existing.position = r.position; existing.needsSync = false
        } else {
            let day = RoutineDay(
                id: r.id, weekday: r.weekday, name: r.name, kind: RoutineKind(rawValue: r.kind) ?? .rest,
                cardioType: r.cardioType, cardioMinutesMin: r.cardioMinutesMin, cardioMinutesMax: r.cardioMinutesMax,
                notes: r.notes, position: r.position, createdAt: r.createdAt, needsSync: false
            )
            context.insert(day)
        }
    }

    private func upsertLocalRoutineExercise(_ r: RemoteRoutineExercise, context: ModelContext) {
        guard let day = findRoutineDay(r.routineDayId, context), let exercise = findExercise(r.exerciseId, context) else { return }
        let existing = try? context.fetch(FetchDescriptor<RoutineExercise>(predicate: #Predicate { $0.id == r.id })).first
        if let existing {
            existing.routineDay = day; existing.exercise = exercise; existing.position = r.position
            existing.targetSets = r.targetSets; existing.targetRepsMin = r.targetRepsMin; existing.targetRepsMax = r.targetRepsMax
            existing.targetRestSeconds = r.targetRestSeconds; existing.notes = r.notes; existing.needsSync = false
        } else {
            let re = RoutineExercise(
                id: r.id, routineDay: day, exercise: exercise, position: r.position,
                targetSets: r.targetSets, targetRepsMin: r.targetRepsMin, targetRepsMax: r.targetRepsMax,
                targetRestSeconds: r.targetRestSeconds, notes: r.notes, createdAt: r.createdAt, needsSync: false
            )
            context.insert(re)
        }
    }

    private func upsertLocalSession(_ r: RemoteWorkoutSession, context: ModelContext) {
        let day = r.routineDayId.flatMap { findRoutineDay($0, context) }
        let date = SupabaseJSON.dateOnlyFormatter.date(from: r.sessionDate) ?? .now
        if let existing = findSession(r.id, context) {
            existing.routineDay = day; existing.sessionDate = date; existing.startedAt = r.startedAt
            existing.finishedAt = r.finishedAt; existing.cardioMinutes = r.cardioMinutes
            existing.cardioType = r.cardioType; existing.notes = r.notes; existing.needsSync = false
        } else {
            let session = WorkoutSession(
                id: r.id, routineDay: day, sessionDate: date, startedAt: r.startedAt, finishedAt: r.finishedAt,
                cardioMinutes: r.cardioMinutes, cardioType: r.cardioType, notes: r.notes,
                createdAt: r.createdAt, needsSync: false
            )
            context.insert(session)
        }
    }

    private func upsertLocalLoggedSet(_ r: RemoteLoggedSet, context: ModelContext) {
        guard let session = findSession(r.sessionId, context), let exercise = findExercise(r.exerciseId, context) else { return }
        let existing = try? context.fetch(FetchDescriptor<LoggedSet>(predicate: #Predicate { $0.id == r.id })).first
        if let existing {
            existing.session = session; existing.exercise = exercise; existing.setNumber = r.setNumber
            existing.reps = r.reps; existing.weightKg = r.weightKg; existing.rpe = r.rpe; existing.notes = r.notes; existing.needsSync = false
        } else {
            let set = LoggedSet(
                id: r.id, session: session, exercise: exercise, setNumber: r.setNumber, reps: r.reps,
                weightKg: r.weightKg, rpe: r.rpe, notes: r.notes, createdAt: r.createdAt, needsSync: false
            )
            context.insert(set)
        }
    }
}
