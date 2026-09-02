//
//  AddRoutineView.swift
//  GymApp
//
//  Created by Gabriel Amaral on 26/08/26.
//

import SwiftUI
import SwiftData

struct AddRoutineView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var workouts: [Workout] = []
    @State private var selectedWorkouts: [Workout?] = []
    @State private var routineName: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Nome", text: $routineName)
                Section("Selecione os treinos da rotina") {
                    ForEach(workouts) { workout in
                        Button {
                            toggleSelection(for: workout)
                        } label: {
                            HStack {
                                Text(workout.name)
                                Spacer()
                                if selectedWorkouts.contains(where: { $0?.id == workout.id }) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveRoutine()
                        dismiss()
                    } label: {
                        Label("Salvar", systemImage: "checkmark")
                    }
                    .disabled(selectedWorkouts.isEmpty || routineName.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Voltar", systemImage: "chevron.left")
                    }
                }
            }
            .navigationTitle("Adicionar rotina")
        }
    }
    
    private func toggleSelection(for workout: Workout) {
        if let index = selectedWorkouts.firstIndex(where: { $0?.id == workout.id }) {
            selectedWorkouts.remove(at: index)
        } else {
            selectedWorkouts.append(workout)
        }
    }

    private func saveRoutine() {
        let newRoutine = RoutineTemplate(name: routineName, workouts: selectedWorkouts as! [Workout])
        modelContext.insert(newRoutine)
        
    }
}

#Preview {
//    AddRoutineView()
}
