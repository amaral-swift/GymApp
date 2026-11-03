import Foundation
import SwiftData

/// Cria a rotina semanal atual do Gabriel (hipertrofia 4x musculação + corrida seg/qua + pedal domingo)
/// como ponto de partida, na primeira vez que ele loga e não existe nenhuma rotina salva ainda.
/// Depois disso, tanto ele quanto o Claude (via Supabase) podem ajustar os treinos.
@MainActor
struct SeedService {
    static func seedDefaultRoutineIfNeeded(context: ModelContext) {
        let existingDays = (try? context.fetchCount(FetchDescriptor<RoutineDay>())) ?? 0
        guard existingDays == 0 else { return }

        func makeExercise(_ name: String, _ muscleGroup: String) -> Exercise {
            let e = Exercise(name: name, muscleGroup: muscleGroup)
            context.insert(e)
            return e
        }

        func addExercise(
            to day: RoutineDay, position: Int, name: String, muscleGroup: String,
            sets: Int, repsMin: Int, repsMax: Int, restSeconds: Int
        ) {
            let ex = makeExercise(name, muscleGroup)
            let re = RoutineExercise(
                routineDay: day, exercise: ex, position: position,
                targetSets: sets, targetRepsMin: repsMin, targetRepsMax: repsMax, targetRestSeconds: restSeconds
            )
            context.insert(re)
        }

        // Segunda — Superior A + corrida
        let seg = RoutineDay(weekday: 1, name: "Superior A", kind: .lifting, cardioType: "corrida", cardioMinutesMin: 25, cardioMinutesMax: 35, position: 1)
        context.insert(seg)
        addExercise(to: seg, position: 1, name: "Supino reto barra", muscleGroup: "Peito", sets: 4, repsMin: 6, repsMax: 10, restSeconds: 120)
        addExercise(to: seg, position: 2, name: "Supino inclinado halteres", muscleGroup: "Peito", sets: 3, repsMin: 8, repsMax: 12, restSeconds: 90)
        addExercise(to: seg, position: 3, name: "Desenvolvimento militar", muscleGroup: "Ombro", sets: 3, repsMin: 8, repsMax: 12, restSeconds: 90)
        addExercise(to: seg, position: 4, name: "Elevação lateral", muscleGroup: "Ombro", sets: 3, repsMin: 12, repsMax: 15, restSeconds: 60)
        addExercise(to: seg, position: 5, name: "Tríceps testa", muscleGroup: "Tríceps", sets: 3, repsMin: 10, repsMax: 12, restSeconds: 60)
        addExercise(to: seg, position: 6, name: "Tríceps corda", muscleGroup: "Tríceps", sets: 2, repsMin: 12, repsMax: 15, restSeconds: 45)

        // Terça — Inferior A
        let ter = RoutineDay(weekday: 2, name: "Inferior A", kind: .lifting, position: 2)
        context.insert(ter)
        addExercise(to: ter, position: 1, name: "Agachamento livre", muscleGroup: "Quadríceps", sets: 4, repsMin: 6, repsMax: 10, restSeconds: 150)
        addExercise(to: ter, position: 2, name: "Leg press", muscleGroup: "Quadríceps", sets: 3, repsMin: 10, repsMax: 12, restSeconds: 90)
        addExercise(to: ter, position: 3, name: "Cadeira extensora", muscleGroup: "Quadríceps", sets: 3, repsMin: 12, repsMax: 15, restSeconds: 60)
        addExercise(to: ter, position: 4, name: "Afundo ou passada", muscleGroup: "Glúteo", sets: 3, repsMin: 10, repsMax: 12, restSeconds: 75)
        addExercise(to: ter, position: 5, name: "Panturrilha em pé", muscleGroup: "Panturrilha", sets: 4, repsMin: 12, repsMax: 15, restSeconds: 45)

        // Quarta — Superior B + corrida
        let qua = RoutineDay(weekday: 3, name: "Superior B", kind: .lifting, cardioType: "corrida", cardioMinutesMin: 25, cardioMinutesMax: 35, position: 3)
        context.insert(qua)
        addExercise(to: qua, position: 1, name: "Barra fixa ou puxada frontal", muscleGroup: "Costas", sets: 4, repsMin: 6, repsMax: 10, restSeconds: 120)
        addExercise(to: qua, position: 2, name: "Remada curvada", muscleGroup: "Costas", sets: 3, repsMin: 8, repsMax: 12, restSeconds: 90)
        addExercise(to: qua, position: 3, name: "Remada unilateral com halter", muscleGroup: "Costas", sets: 3, repsMin: 10, repsMax: 12, restSeconds: 75)
        addExercise(to: qua, position: 4, name: "Abdominal", muscleGroup: "Core", sets: 4, repsMin: 15, repsMax: 15, restSeconds: 45)
        addExercise(to: qua, position: 5, name: "Rosca direta barra", muscleGroup: "Bíceps", sets: 3, repsMin: 10, repsMax: 12, restSeconds: 60)
        addExercise(to: qua, position: 6, name: "Rosca martelo", muscleGroup: "Bíceps", sets: 2, repsMin: 12, repsMax: 15, restSeconds: 45)

        // Quinta — Inferior B
        let qui = RoutineDay(weekday: 4, name: "Inferior B", kind: .lifting, position: 4)
        context.insert(qui)
        addExercise(to: qui, position: 1, name: "Levantamento terra romeno (RDL)", muscleGroup: "Posterior de coxa", sets: 4, repsMin: 8, repsMax: 10, restSeconds: 120)
        addExercise(to: qui, position: 2, name: "Mesa flexora", muscleGroup: "Posterior de coxa", sets: 3, repsMin: 12, repsMax: 15, restSeconds: 60)
        addExercise(to: qui, position: 3, name: "Cadeira adutora", muscleGroup: "Adutores", sets: 3, repsMin: 15, repsMax: 15, restSeconds: 45)
        addExercise(to: qui, position: 4, name: "Panturrilha sentado", muscleGroup: "Panturrilha", sets: 3, repsMin: 15, repsMax: 20, restSeconds: 45)
        addExercise(to: qui, position: 5, name: "Panturrilha de pé", muscleGroup: "Panturrilha", sets: 3, repsMin: 15, repsMax: 20, restSeconds: 60)

        // Sexta — Descanso
        context.insert(RoutineDay(weekday: 5, name: "Descanso", kind: .rest, position: 5))

        // Sábado — só corrida
        context.insert(RoutineDay(
            weekday: 6, name: "Corrida", kind: .cardio, cardioType: "corrida",
            notes: "Dia sem musculação — pode ser a rodagem mais longa ou mais intensa da semana.", position: 6
        ))

        // Domingo — Pedal
        context.insert(RoutineDay(
            weekday: 7, name: "Pedal", kind: .cardio, cardioType: "pedal", cardioMinutesMin: 40, cardioMinutesMax: 60,
            notes: "Ritmo moderado, zona 2 (RPE 5-6/10). Atividade nova: comece nessa faixa e aumente gradualmente nas primeiras semanas.",
            position: 7
        ))

        try? context.save()
    }
}
