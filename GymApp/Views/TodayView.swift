import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var syncService: SyncService

    @Query(sort: \RoutineDay.position) private var allDays: [RoutineDay]
    @Query private var allSessions: [WorkoutSession]

    @State private var isSyncing = false
    @State private var addSetTarget: RoutineExercise?
    @State private var cardioMinutesText: String = ""

    private var today: RoutineDay? {
        allDays.first { $0.weekday == Date().isoWeekday }
    }

    private var todaySession: WorkoutSession? {
        allSessions.first { Calendar.current.isDate($0.sessionDate, inSameDayAs: .now) }
    }

    var body: some View {
        NavigationStack {
            List {
                if let today {
                    Section {
                        HStack {
                            Text(today.name).font(.headline)
                            Spacer()
                            Text(RoutineDay.weekdayNames[today.weekday]).foregroundStyle(.secondary)
                        }
                    }

                    if let cardioType = today.cardioType {
                        Section("Cardio") {
                            cardioRow(type: cardioType, minMin: today.cardioMinutesMin, minMax: today.cardioMinutesMax, notes: today.notes)
                        }
                    }

                    if !today.exercises.isEmpty {
                        Section("Exercícios") {
                            ForEach(today.exercises.sorted(by: { $0.position < $1.position })) { re in
                                exerciseRow(re)
                            }
                        }
                    }

                    if today.exercises.isEmpty && today.cardioType == nil {
                        Section {
                            Text("Dia de descanso. 🙌").foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("Nenhum treino cadastrado pra hoje ainda. Toque em sincronizar ou confira a aba Rotina.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Hoje")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            isSyncing = true
                            await syncService.sync(context: context)
                            isSyncing = false
                        }
                    } label: {
                        if isSyncing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                    }
                }
            }
            .sheet(item: $addSetTarget) { re in
                AddSetSheet(routineExercise: re, session: ensureTodaySession())
            }
            .onAppear {
                if let existing = todaySession?.cardioMinutes {
                    cardioMinutesText = String(existing)
                }
            }
        }
    }

    private func exerciseRow(_ re: RoutineExercise) -> some View {
        let loggedCount = todaySession?.loggedSets.filter { $0.exercise?.id == re.exercise?.id }.count ?? 0
        return Button {
            addSetTarget = re
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(re.exercise?.name ?? "—")
                        .foregroundStyle(.primary)
                    Text("\(re.targetSets ?? 0)x\(re.repsRangeLabel) · descanso \(re.targetRestSeconds ?? 0)s")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if loggedCount > 0 {
                    Text("\(loggedCount) série(s)")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.blue)
            }
        }
        .buttonStyle(.plain)
    }

    private func cardioRow(type: String, minMin: Int?, minMax: Int?, notes: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(type.capitalized)
                Spacer()
                if let minMin, let minMax {
                    Text("\(minMin)-\(minMax) min").foregroundStyle(.secondary)
                } else if let minMin {
                    Text("\(minMin)+ min").foregroundStyle(.secondary)
                }
            }
            if let notes, !notes.isEmpty {
                Text(notes).font(.caption).foregroundStyle(.secondary)
            }
            HStack {
                Text("Minutos feitos:")
                TextField("ex: 30", text: $cardioMinutesText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                Button("Salvar") { saveCardio(type: type) }
                    .buttonStyle(.bordered)
            }
        }
    }

    private func saveCardio(type: String) {
        let session = ensureTodaySession()
        session.cardioType = type
        session.cardioMinutes = Int(cardioMinutesText)
        session.needsSync = true
        try? context.save()
    }

    @discardableResult
    private func ensureTodaySession() -> WorkoutSession {
        if let existing = todaySession { return existing }
        let session = WorkoutSession(routineDay: today, sessionDate: .now, startedAt: .now)
        context.insert(session)
        try? context.save()
        return session
    }
}
