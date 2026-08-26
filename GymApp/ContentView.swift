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
    @Query private var items: [Item]
    @Query private var exerciseSets: [ExerciseSet]
    @Query private var exercises: [Exercise]
    @Query private var routineTemapletes: [RoutineTemplate]
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
                            NavigationLink(workout.name, destination: WorkoutView(workout: workout))
                        }
                    }
                }
            }
            .sheet(isPresented: $addingWorkout) {
                AddWorkoutView()
            }
            .toolbar {
                ToolbarItem {
                    Button(action: addWorkout) {
                        Label("Add Sample Data", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Treinos")
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
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
    
    private func seedSampleData() {
        let supino = Exercise(name: "Supino Reto", series: 4, repetition: 10, rest: 90)
        let agachamento = Exercise(name: "Agachamento Livre", series: 4, repetition: 8, rest: 120)
        let rosca = Exercise(name: "Rosca Direta", series: 3, repetition: 12, rest: 60)
        
        let peitoTriceps = ExerciseSet(name: "Peito e Tríceps", exercises: [supino, rosca])
        let pernas = ExerciseSet(name: "Pernas", exercises: [agachamento])
        
        let treinoA = Workout(name: "Treino A", exerciseSets: [peitoTriceps], weekDay: .monday, type: .ABC)
        let treinoB = Workout(name: "Treino B", exerciseSets: [pernas], weekDay: .wednesday, type: .ABC)
        
        let rotina = RoutineTemplate(name: "Rotina Iniciante", workouts: [treinoA, treinoB])
        
        let rotinaMenor = RoutineTemplate(name: "Rotina Menor", workouts: [treinoA])
        
        modelContext.insert(rotina)
        modelContext.insert(rotinaMenor)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: RoutineTemplate.self, inMemory: true)
}
