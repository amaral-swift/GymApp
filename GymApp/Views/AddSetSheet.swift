import SwiftUI
import SwiftData

struct AddSetSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let routineExercise: RoutineExercise
    let session: WorkoutSession

    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var rpe: Double = 8
    @State private var notes: String = ""

    private var existingSetsForExercise: [LoggedSet] {
        session.loggedSets
            .filter { $0.exercise?.id == routineExercise.exercise?.id }
            .sorted { $0.setNumber < $1.setNumber }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(routineExercise.exercise?.name ?? "Exercício") {
                    Text("Meta: \(routineExercise.targetSets ?? 0)x\(routineExercise.repsRangeLabel) · descanso \(routineExercise.targetRestSeconds ?? 0)s")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !existingSetsForExercise.isEmpty {
                    Section("Séries de hoje") {
                        ForEach(existingSetsForExercise) { set in
                            HStack {
                                Text("Série \(set.setNumber)")
                                Spacer()
                                Text("\(formattedWeight(set.weightKg)) kg × \(set.reps ?? 0)")
                                if let rpe = set.rpe {
                                    Text("RPE \(formattedDecimal(rpe))").foregroundStyle(.secondary)
                                }
                            }
                            .font(.subheadline)
                        }
                        .onDelete(perform: deleteSets)
                    }
                }

                Section("Nova série") {
                    TextField("Peso (kg)", text: $weightText)
                        .keyboardType(.decimalPad)
                    TextField("Repetições", text: $repsText)
                        .keyboardType(.numberPad)
                    VStack(alignment: .leading) {
                        Text("RPE: \(formattedDecimal(rpe))")
                        Slider(value: $rpe, in: 1...10, step: 0.5)
                    }
                    TextField("Observações (opcional)", text: $notes)
                }
            }
            .navigationTitle("Registrar série")
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { save() }
                        .disabled(repsText.isEmpty)
                }
            }
        }
    }

    private func save() {
        guard let exercise = routineExercise.exercise else { return }
        let nextNumber = (existingSetsForExercise.map(\.setNumber).max() ?? 0) + 1
        let set = LoggedSet(
            session: session,
            exercise: exercise,
            setNumber: nextNumber,
            reps: Int(repsText),
            weightKg: Double(weightText.replacingOccurrences(of: ",", with: ".")),
            rpe: rpe,
            notes: notes.isEmpty ? nil : notes
        )
        context.insert(set)
        session.needsSync = true
        try? context.save()
        weightText = ""
        repsText = ""
        notes = ""
        dismiss()
    }

    private func deleteSets(at offsets: IndexSet) {
        for index in offsets {
            context.delete(existingSetsForExercise[index])
        }
        try? context.save()
    }

    private func formattedWeight(_ value: Double?) -> String {
        guard let value else { return "-" }
        return formattedDecimal(value)
    }

    private func formattedDecimal(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.1f", value)
    }
}
