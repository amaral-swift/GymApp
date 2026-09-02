//
//  ExercisesView.swift
//  GymApp
//
//  Created by Gabriel Amaral on 26/08/26.
//

import SwiftUI
import SwiftData

struct ExercisesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [Exercise]
    @Query private var workouts: [Workout]
    @State private var addingExercise: Bool = false
    @State private var linkingExercise: Exercise?

    var body: some View {
        NavigationStack {
            Group {
                if exercises.isEmpty {
                    ContentUnavailableView("Sem exercícios", systemImage: "figure.gymnastics", description: Text("Adicione um exercício para começar"))
                } else {
                    List {
                        ForEach(exercises) { exercise in
                            Text(exercise.name)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteExercise(exercise)
                                    } label: {
                                        Label("Excluir", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        linkingExercise = exercise
                                    } label: {
                                        Label("Vincular a treino", systemImage: "link")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                }
            }
            .sheet(isPresented: $addingExercise) {
                AddExerciseView()
            }
            .sheet(item: $linkingExercise) { exercise in
                NavigationStack {
                    List(workouts) { workout in
                        Button {
                            toggleWorkout(workout, for: exercise)
                        } label: {
                            HStack {
                                Text(workout.name)
                                Spacer()
                                if exercise.workouts.contains(where: { $0.id == workout.id }) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                    .navigationTitle("Vincular a treino")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Concluído") {
                                linkingExercise = nil
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        addingExercise = true
                    } label: {
                        Label("Add exercise", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Exercícios")
        }
    }
    
    private func deleteExercise(_ exercise: Exercise) {
        withAnimation {
            modelContext.delete(exercise)
        }
    }

    private func toggleWorkout(_ workout: Workout, for exercise: Exercise) {
        if let index = exercise.workouts.firstIndex(where: { $0.id == workout.id }) {
            exercise.workouts.remove(at: index)
        } else {
            exercise.workouts.append(workout)
        }
    }
}

#Preview {
    ExercisesView()
}
