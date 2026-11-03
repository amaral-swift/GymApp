import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(exercises) { exercise in
                    NavigationLink {
                        ExerciseDetailView(exercise: exercise)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(exercise.name)
                            if let mg = exercise.muscleGroup {
                                Text(mg).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Exercícios")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddExerciseSheet()
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { context.delete(exercises[index]) }
        try? context.save()
    }
}

struct AddExerciseSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var muscleGroup = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Nome", text: $name)
                TextField("Grupo muscular", text: $muscleGroup)
                TextField("Observações", text: $notes)
            }
            .navigationTitle("Novo exercício")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Fechar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { save() }.disabled(name.isEmpty)
                }
            }
        }
    }

    private func save() {
        let exercise = Exercise(name: name, muscleGroup: muscleGroup.isEmpty ? nil : muscleGroup, notes: notes.isEmpty ? nil : notes)
        context.insert(exercise)
        try? context.save()
        dismiss()
    }
}

struct ExerciseDetailView: View {
    let exercise: Exercise
    @Query private var allSets: [LoggedSet]

    private var history: [LoggedSet] {
        allSets
            .filter { $0.exercise?.id == exercise.id }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        List {
            Section("Histórico recente") {
                if history.isEmpty {
                    Text("Nenhuma série registrada ainda.").foregroundStyle(.secondary)
                } else {
                    ForEach(history.prefix(20)) { set in
                        HStack {
                            Text(set.createdAt.formatted(date: .abbreviated, time: .omitted))
                            Spacer()
                            Text("\(weightLabel(set.weightKg)) kg × \(set.reps ?? 0)")
                            if let rpe = set.rpe {
                                Text("RPE \(decimalLabel(rpe))").foregroundStyle(.secondary)
                            }
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle(exercise.name)
    }

    private func weightLabel(_ value: Double?) -> String {
        guard let value else { return "-" }
        return decimalLabel(value)
    }

    private func decimalLabel(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.1f", value)
    }
}
