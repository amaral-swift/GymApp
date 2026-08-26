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
        let exercise = Exercise(name: exerciseName, series: seriesQuantity, repetition: repetitionQuantity, rest: restTime!)
        modelContext.insert(exercise)
    }
}

#Preview {
    AddExerciseView()
}
