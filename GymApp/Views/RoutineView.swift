import SwiftUI
import SwiftData

struct RoutineView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \RoutineDay.position) private var days: [RoutineDay]

    @State private var addExerciseDay: RoutineDay?
    @State private var editingExercise: RoutineExercise?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Os treinos de musculação seguem em sequência (Superior A → Inferior A → Superior B → Inferior B), não presos a um dia fixo. Se você pular um dia, o próximo treino continua de onde parou. Corrida e pedal continuam nos dias certos.")
                        .font(AppFont.caption(12))
                        .foregroundStyle(AppColor.textSecondary)
                }

                ForEach(days) { day in
                    Section {
                        if let cardioType = day.cardioType {
                            HStack {
                                Image(systemName: "figure.run")
                                Text(cardioType.capitalized)
                                Spacer()
                                if let min = day.cardioMinutesMin, let max = day.cardioMinutesMax {
                                    Text("\(min)-\(max) min").foregroundStyle(.secondary)
                                }
                            }
                            .font(.subheadline)
                        }

                        ForEach(day.exercises.sorted(by: { $0.position < $1.position })) { re in
                            Button {
                                editingExercise = re
                            } label: {
                                HStack {
                                    Text(re.exercise?.name ?? "—")
                                    Spacer()
                                    Text("\(re.targetSets ?? 0)x\(re.repsRangeLabel)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { offsets in deleteExercises(from: day, at: offsets) }

                        Button {
                            addExerciseDay = day
                        } label: {
                            Label("Adicionar exercício", systemImage: "plus")
                        }
                    } header: {
                        if day.kind == .lifting {
                            Text("Treino \(day.position) · \(day.name)")
                        } else {
                            Text("\(RoutineDay.weekdayNames[day.weekday]) · \(day.name)")
                        }
                    } footer: {
                        if let notes = day.notes, !notes.isEmpty {
                            Text(notes)
                        }
                    }
                }
            }
            .navigationTitle("Rotina semanal")
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .sheet(item: $addExerciseDay) { day in
                AddRoutineExerciseSheet(day: day)
            }
            .sheet(item: $editingExercise) { re in
                EditRoutineExerciseSheet(routineExercise: re)
            }
        }
    }

    private func deleteExercises(from day: RoutineDay, at offsets: IndexSet) {
        let sorted = day.exercises.sorted(by: { $0.position < $1.position })
        for index in offsets {
            context.delete(sorted[index])
        }
        try? context.save()
    }
}

struct EditRoutineExerciseSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let routineExercise: RoutineExercise

    @State private var sets: Int
    @State private var repsMin: Int
    @State private var repsMax: Int
    @State private var restSeconds: Int
    @State private var notes: String

    init(routineExercise: RoutineExercise) {
        self.routineExercise = routineExercise
        _sets = State(initialValue: routineExercise.targetSets ?? 3)
        _repsMin = State(initialValue: routineExercise.targetRepsMin ?? 8)
        _repsMax = State(initialValue: routineExercise.targetRepsMax ?? 12)
        _restSeconds = State(initialValue: routineExercise.targetRestSeconds ?? 60)
        _notes = State(initialValue: routineExercise.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Stepper("Séries: \(sets)", value: $sets, in: 1...10)
                Stepper("Reps mín: \(repsMin)", value: $repsMin, in: 1...30)
                Stepper("Reps máx: \(repsMax)", value: $repsMax, in: repsMin...30)
                Stepper("Descanso: \(restSeconds)s", value: $restSeconds, in: 15...240, step: 15)
                TextField("Observações", text: $notes)
            }
            .navigationTitle(routineExercise.exercise?.name ?? "Exercício")
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Fechar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { save() }
                }
            }
        }
    }

    private func save() {
        routineExercise.targetSets = sets
        routineExercise.targetRepsMin = repsMin
        routineExercise.targetRepsMax = repsMax
        routineExercise.targetRestSeconds = restSeconds
        routineExercise.notes = notes.isEmpty ? nil : notes
        routineExercise.needsSync = true
        try? context.save()
        dismiss()
    }
}

struct AddRoutineExerciseSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let day: RoutineDay

    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    @State private var searchText = ""
    @State private var newExerciseName = ""
    @State private var newMuscleGroup = ""

    private var filtered: [Exercise] {
        searchText.isEmpty ? allExercises : allExercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Criar novo exercício") {
                    TextField("Nome", text: $newExerciseName)
                    TextField("Grupo muscular", text: $newMuscleGroup)
                    Button("Adicionar") { addNew() }
                        .disabled(newExerciseName.isEmpty)
                }
                Section("Ou escolher existente") {
                    ForEach(filtered) { exercise in
                        Button {
                            addExisting(exercise)
                        } label: {
                            HStack {
                                Text(exercise.name)
                                Spacer()
                                if let mg = exercise.muscleGroup {
                                    Text(mg).foregroundStyle(.secondary).font(.caption)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Adicionar exercício")
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Fechar") { dismiss() } }
            }
        }
    }

    private func nextPosition() -> Int {
        (day.exercises.map(\.position).max() ?? 0) + 1
    }

    private func addExisting(_ exercise: Exercise) {
        let re = RoutineExercise(
            routineDay: day, exercise: exercise, position: nextPosition(),
            targetSets: 3, targetRepsMin: 8, targetRepsMax: 12, targetRestSeconds: 60
        )
        context.insert(re)
        try? context.save()
        dismiss()
    }

    private func addNew() {
        let exercise = Exercise(name: newExerciseName, muscleGroup: newMuscleGroup.isEmpty ? nil : newMuscleGroup)
        context.insert(exercise)
        addExisting(exercise)
    }
}
