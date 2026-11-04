import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var syncService: SyncService
    @Query(sort: [SortDescriptor(\WorkoutSession.sessionDate, order: .reverse)]) private var sessions: [WorkoutSession]

    var body: some View {
        NavigationStack {
            List {
                if sessions.isEmpty {
                    Text("Nenhum treino registrado ainda.").foregroundStyle(.secondary)
                }
                ForEach(sessions) { session in
                    NavigationLink {
                        SessionDetailView(session: session)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(session.routineDay?.name ?? session.cardioType?.capitalized ?? "Treino")
                                    .font(.headline)
                                Spacer()
                                Text(session.sessionDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            HStack(spacing: 12) {
                                if !session.loggedSets.isEmpty {
                                    Label("\(session.loggedSets.count) séries", systemImage: "dumbbell")
                                } else if session.cardioMinutes == nil {
                                    Label("Vazio", systemImage: "exclamationmark.circle")
                                }
                                if let minutes = session.cardioMinutes {
                                    Label("\(minutes) min \(session.cardioType ?? "")", systemImage: "figure.run")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteSessions)
            }
            .navigationTitle("Histórico")
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
        }
    }

    private func deleteSessions(at offsets: IndexSet) {
        let toDelete = offsets.map { sessions[$0] }
        for session in toDelete {
            Task {
                await syncService.deleteSession(session, context: context)
            }
        }
    }
}

struct SessionDetailView: View {
    let session: WorkoutSession

    private var groupedByExercise: [(Exercise, [LoggedSet])] {
        let grouped = Dictionary(grouping: session.loggedSets) { $0.exercise?.id ?? UUID() }
        return grouped.compactMap { _, sets -> (Exercise, [LoggedSet])? in
            guard let exercise = sets.first?.exercise else { return nil }
            return (exercise, sets.sorted { $0.setNumber < $1.setNumber })
        }
        .sorted { $0.0.name < $1.0.name }
    }

    var body: some View {
        List {
            Section {
                if let minutes = session.cardioMinutes {
                    Text("\(session.cardioType?.capitalized ?? "Cardio"): \(minutes) min")
                }
                if let notes = session.notes, !notes.isEmpty {
                    Text(notes).foregroundStyle(.secondary)
                }
            }
            ForEach(groupedByExercise, id: \.0.id) { exercise, sets in
                Section(exercise.name) {
                    ForEach(sets) { set in
                        HStack {
                            Text("Série \(set.setNumber)")
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
        .navigationTitle(session.routineDay?.name ?? "Treino")
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
    }

    private func weightLabel(_ value: Double?) -> String {
        guard let value else { return "-" }
        return decimalLabel(value)
    }

    private func decimalLabel(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.1f", value)
    }
}
