//
//  AddWorkoutView.swift
//  GymApp
//
//  Created by Gabriel Amaral on 25/08/26.
//

import SwiftUI
import SwiftData

struct AddWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var routineTemplates: [RoutineTemplate]
    @Query private var exercises: [Exercise]

    @State private var name: String = ""
    @State private var type: workoutType = .ABC
    @State private var workoutDay: weekDay = .monday
    @State private var selectedRoutineTemplate: RoutineTemplate?
    @State private var selectedExercises: [Exercise?] = []

    var body: some View {
        NavigationStack {
            Form {
                TextField("Nome", text: $name)
                
                Picker("Tipo de treino", selection: $type) {
                    ForEach(workoutType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                
                Picker("Rotina", selection: $selectedRoutineTemplate) {
                    Text("Nenhuma").tag(nil as RoutineTemplate?)
                    ForEach(routineTemplates) { routine in
                        Text(routine.name).tag(routine as RoutineTemplate?)
                    }
                }
                Section("Exercícios") {
                    ForEach(exercises) { exercise in
                        Button {
                            toggleSelection(for: exercise)
                        } label: {
                            HStack {
                                Text(exercise.name)
                                Spacer()
                                if selectedExercises.contains(where: { $0?.id == exercise.id }) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle(Text("Adicionar treino"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Voltar", systemImage: "chevron.left")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveWorkout()
                        dismiss()
                    } label: {
                        Label("Salvar", systemImage: "checkmark")
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveWorkout() {
        let workout = Workout(name: name, exerciseSets: [], weekDay: workoutDay, type: type)
        modelContext.insert(workout)

        for exercise in selectedExercises.compactMap({ $0 }) {
            let nextOrder = (workout.exerciseSets.map(\.order).max() ?? -1) + 1
            let workoutExercise = WorkoutExercise(order: nextOrder, exercises: exercise, workouts: workout)
            modelContext.insert(workoutExercise)
        }
    }
    
    private func toggleSelection(for exercise: Exercise) {
        if let index = selectedExercises.firstIndex(where: { $0?.id == exercise.id }) {
            selectedExercises.remove(at: index)
        } else {
            selectedExercises.append(exercise)
        }
    }
}

#Preview {
    AddWorkoutView()
        .modelContainer(for: RoutineTemplate.self, inMemory: true)
}
