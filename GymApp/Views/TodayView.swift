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
            ScrollView {
                VStack(alignment: .leading, spacing: AppMetrics.spacing) {
                    if let today {
                        header(for: today)

                        if let cardioType = today.cardioType {
                            cardioCard(day: today, type: cardioType)
                        }

                        if !today.exercises.isEmpty {
                            SectionHeaderLabel(text: "Exercícios")
                                .padding(.top, 4)
                            VStack(spacing: 10) {
                                ForEach(today.exercises.sorted(by: { $0.position < $1.position })) { re in
                                    exerciseCard(re)
                                }
                            }
                        }

                        if today.exercises.isEmpty && today.cardioType == nil {
                            VStack(spacing: 10) {
                                Image(systemName: "moon.zzz.fill")
                                    .font(.system(size: 34))
                                    .foregroundStyle(AppColor.rest)
                                Text("Dia de descanso")
                                    .font(AppFont.headline())
                                    .foregroundStyle(AppColor.textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .cardStyle()
                        }
                    } else {
                        Text("Nenhum treino cadastrado pra hoje ainda. Toque em sincronizar ou confira a aba Rotina.")
                            .foregroundStyle(AppColor.textSecondary)
                            .padding()
                    }
                }
                .padding(16)
            }
            .screenBackground()
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
                    .tint(AppColor.strength)
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

    private func header(for day: RoutineDay) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 6) {
                Text(RoutineDay.weekdayNames[day.weekday].uppercased())
                    .font(AppFont.caption(12))
                    .foregroundStyle(AppColor.textSecondary)
                Text(day.name)
                    .font(AppFont.largeTitle(28))
                    .foregroundStyle(AppColor.textPrimary)
            }
            Spacer()
            Image(systemName: day.kind.symbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(day.kind.accentColor)
                .padding(14)
                .background(day.kind.accentColor.opacity(0.16), in: Circle())
        }
    }

    private func cardioCard(day: RoutineDay, type: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TagView(text: type.capitalized, color: AppColor.cardio, systemImage: "figure.run")
                Spacer()
                if let minMin = day.cardioMinutesMin, let minMax = day.cardioMinutesMax {
                    Text("\(minMin)-\(minMax) min")
                        .font(AppFont.numeric(14))
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            if let notes = day.notes, !notes.isEmpty {
                Text(notes)
                    .font(AppFont.caption(13))
                    .foregroundStyle(AppColor.textSecondary)
            }
            HStack {
                Text("Minutos feitos")
                    .font(AppFont.body(14))
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                TextField("0", text: $cardioMinutesText)
                    .keyboardType(.numberPad)
                    .font(AppFont.numeric(16))
                    .foregroundStyle(AppColor.textPrimary)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .padding(.vertical, 8).padding(.horizontal, 10)
                    .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                Button("Salvar") { saveCardio(type: type) }
                    .font(AppFont.caption(13).weight(.bold))
                    .foregroundStyle(AppColor.cardio)
            }
        }
        .cardStyle()
    }

    private func exerciseCard(_ re: RoutineExercise) -> some View {
        let loggedCount = todaySession?.loggedSets.filter { $0.exercise?.id == re.exercise?.id }.count ?? 0
        return Button {
            addSetTarget = re
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(re.exercise?.name ?? "—")
                        .font(AppFont.headline())
                        .foregroundStyle(AppColor.textPrimary)
                    Text("\(re.targetSets ?? 0)x\(re.repsRangeLabel) · descanso \(re.targetRestSeconds ?? 0)s")
                        .font(AppFont.caption(12))
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer()
                if loggedCount > 0 {
                    TagView(text: "\(loggedCount)", color: AppColor.success, systemImage: "checkmark")
                }
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppColor.strength)
            }
        }
        .buttonStyle(.plain)
        .cardStyle()
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
