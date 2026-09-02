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

    @State private var name: String = ""
    @State private var type: workoutType = .ABC
    @State private var workoutDay: weekDay = .monday
    @State private var selectedRoutineTemplate: RoutineTemplate?

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
        let workout = Workout(name: name, exercises: [], weekDay: workoutDay, type: type)
        modelContext.insert(workout)
    }
}

#Preview {
    AddWorkoutView()
        .modelContainer(for: RoutineTemplate.self, inMemory: true)
}
