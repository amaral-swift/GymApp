//
//  ContentView.swift
//  GymApp
//
//  Created by Gabriel Amaral on 24/08/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var workouts: [Workout]
    @State private var addingWorkout: Bool = false
    
    var body: some View {
        NavigationStack {
            Group {
                if workouts.isEmpty {
                    ContentUnavailableView("Sem treinos", systemImage: "dumbbell", description: Text("Adicione um treino para começar"))
                } else {
                    List {
                        ForEach(workouts) { workout in
                            NavigationLink(destination: WorkoutView(workout: workout)) {
                                VStack(alignment: .leading) {
                                    Text(workout.name)
                                    if let routineTemplate = workout.routineTemplate, !routineTemplate.isEmpty {
                                        HStack {
                                            Text("Rotinas:")
                                                .bold()
                                            Text(routineTemplate.map(\.name).joined(separator: ", "))
                                        }
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteWorkout)
                    }
                }
            }
            .sheet(isPresented: $addingWorkout) {
                AddWorkoutView()
            }
            .toolbar {
                ToolbarItem {
                    Button(action: addWorkout) {
                        Label("Add Workout", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Treinos")
        }
    }
    
    private func deleteWorkout(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(workouts[index])
            }
        }
    }
    
    private func addItem() {
        withAnimation {
            seedSampleData()
        }
    }
    
    private func addWorkout() {
        withAnimation {
            addingWorkout = true
        }
    }
    
    private func seedSampleData() {
        // Treino A - Peito, Ombro e Tríceps
        let peito = [
            Exercise(name: "Supino Reto com Barra", series: 4, repetition: 10, rest: 90),
            Exercise(name: "Supino Inclinado com Halteres", series: 3, repetition: 12, rest: 90),
            Exercise(name: "Crucifixo na Máquina", series: 3, repetition: 15, rest: 60),
            Exercise(name: "Crossover", series: 3, repetition: 15, rest: 60)
        ]
        let ombro = [
            Exercise(name: "Desenvolvimento Militar", series: 4, repetition: 10, rest: 90),
            Exercise(name: "Elevação Lateral", series: 3, repetition: 15, rest: 45),
            Exercise(name: "Elevação Frontal", series: 3, repetition: 15, rest: 45)
        ]
        let triceps = [
            Exercise(name: "Tríceps Corda", series: 3, repetition: 12, rest: 60),
            Exercise(name: "Tríceps Testa", series: 3, repetition: 10, rest: 60)
        ]
        let treinoA = Workout(name: "Treino A - Peito, Ombro e Tríceps", exerciseSets: [], weekDay: .monday, type: .ABC)
        linkExercises(peito + ombro + triceps, to: treinoA)

        // Treino B - Costas e Bíceps
        let costas = [
            Exercise(name: "Puxada Frontal", series: 4, repetition: 10, rest: 90),
            Exercise(name: "Remada Curvada com Barra", series: 4, repetition: 10, rest: 90),
            Exercise(name: "Remada Unilateral com Halter", series: 3, repetition: 12, rest: 60),
            Exercise(name: "Pull-down", series: 3, repetition: 12, rest: 60)
        ]
        let biceps = [
            Exercise(name: "Rosca Direta com Barra", series: 3, repetition: 12, rest: 60),
            Exercise(name: "Rosca Alternada com Halteres", series: 3, repetition: 12, rest: 60),
            Exercise(name: "Rosca Scott", series: 3, repetition: 10, rest: 60)
        ]
        let treinoB = Workout(name: "Treino B - Costas e Bíceps", exerciseSets: [], weekDay: .wednesday, type: .ABC)
        linkExercises(costas + biceps, to: treinoB)

        // Treino C - Pernas e Panturrilha
        let pernas = [
            Exercise(name: "Agachamento Livre", series: 4, repetition: 8, rest: 120),
            Exercise(name: "Leg Press 45°", series: 4, repetition: 12, rest: 90),
            Exercise(name: "Cadeira Extensora", series: 3, repetition: 15, rest: 60),
            Exercise(name: "Mesa Flexora", series: 3, repetition: 15, rest: 60),
            Exercise(name: "Cadeira Adutora", series: 3, repetition: 15, rest: 45)
        ]
        let panturrilha = [
            Exercise(name: "Panturrilha em Pé", series: 4, repetition: 20, rest: 45),
            Exercise(name: "Panturrilha Sentado", series: 3, repetition: 20, rest: 45)
        ]
        let treinoC = Workout(name: "Treino C - Pernas e Panturrilha", exerciseSets: [], weekDay: .friday, type: .ABC)
        linkExercises(pernas + panturrilha, to: treinoC)

        let rotinaHipertrofia = RoutineTemplate(name: "Hipertrofia ABC", workouts: [treinoA, treinoB, treinoC])

        // Treino Full Body - iniciante, 3x na semana
        let fullBodySegunda = [
            Exercise(name: "Agachamento com Peso Corporal", series: 3, repetition: 15, rest: 60),
            Exercise(name: "Flexão de Braço", series: 3, repetition: 12, rest: 60),
            Exercise(name: "Remada com Halteres", series: 3, repetition: 12, rest: 60),
            Exercise(name: "Prancha Abdominal", series: 3, repetition: 30, rest: 45)
        ]
        let treinoFullBodyA = Workout(name: "Full Body A", exerciseSets: [], weekDay: .tuesday, type: .ABC)
        linkExercises(fullBodySegunda, to: treinoFullBodyA)

        let fullBodyQuinta = [
            Exercise(name: "Afundo com Halteres", series: 3, repetition: 12, rest: 60),
            Exercise(name: "Desenvolvimento com Halteres", series: 3, repetition: 12, rest: 60),
            Exercise(name: "Puxada Frontal", series: 3, repetition: 12, rest: 60),
            Exercise(name: "Abdominal Supra", series: 3, repetition: 20, rest: 45)
        ]
        let treinoFullBodyB = Workout(name: "Full Body B", exerciseSets: [], weekDay: .thursday, type: .ABC)
        linkExercises(fullBodyQuinta, to: treinoFullBodyB)

        let rotinaIniciante = RoutineTemplate(name: "Full Body Iniciante", workouts: [treinoFullBodyA, treinoFullBodyB])

        modelContext.insert(rotinaHipertrofia)
        modelContext.insert(rotinaIniciante)
    }

    private func linkExercises(_ exercises: [Exercise], to workout: Workout) {
        for (index, exercise) in exercises.enumerated() {
            let workoutExercise = WorkoutExercise(order: index, exercises: exercise, workouts: workout)
            modelContext.insert(workoutExercise)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: RoutineTemplate.self, inMemory: true)
}
