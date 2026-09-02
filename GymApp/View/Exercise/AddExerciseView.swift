//
//  AddExerciseView.swift
//  GymApp
//
//  Created by Gabriel Amaral on 26/08/26.
//

import SwiftUI
import SwiftData

struct AddExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var exerciseName: String = ""
    @State private var seriesQuantity: Int = 0
    @State private var repetitionQuantity: Int = 0
    @State private var restTime: Int? = nil
    @State private var selectedWorkouts: [Workout?] = []
    @Query private var workouts: [Workout] = []
    var body: some View {
        NavigationStack {
            Form {
                TextField("Nome", text: $exerciseName)
                Picker("Séries", selection: $seriesQuantity) {
                    ForEach(1...20, id: \.self) { i in
                        Text("\(i)")
                    }
                }
                Picker("Repetições", selection: $repetitionQuantity) {
                    ForEach(1...50, id: \.self) { j in
                        Text("\(j)")
                    }
                }
                HStack {
                    Text("Tempo de descanso")
                    
                    Spacer()
                    
                    TextField("0", value: $restTime, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                    Text("s")
                }
                
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
            .navigationTitle("Adicionar exercício")
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
                        addExercise()
                        dismiss()
                    } label: {
                        Label("Salvar", systemImage: "checkmark")
                    }
                    .disabled(restTime == nil)
                }
            }
        }
    }
    
    private func addExercise() {
        guard let restTime else { return }
        let exercise = Exercise(name: exerciseName, series: seriesQuantity, repetition: repetitionQuantity, rest: restTime)
        exercise.workouts = selectedWorkouts.compactMap { $0 }
        modelContext.insert(exercise)
    }
    
    private func toggleSelection(for workout: Workout) {
        if let index = selectedWorkouts.firstIndex(where: { $0?.id == workout.id }) {
            selectedWorkouts.remove(at: index)
        } else {
            selectedWorkouts.append(workout)
        }
    }
}

#Preview {
    AddExerciseView()
}
