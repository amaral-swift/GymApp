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

    /// Dia de referência do calendário (pra corrida/pedal, que ficam fixos em dias certos).
    private var todaySchedule: RoutineDay? {
        allDays.first { $0.weekday == Date().isoWeekday }
    }

    /// Próximo treino de musculação na sequência (Superior A → Inferior A → Superior B → Inferior B),
    /// baseado no último treino concluído — não no dia da semana. Assim, se você pula um dia,
    /// o próximo treino continua de onde parou, em vez de pular pro "treino do dia" seguinte.
    private var nextLiftingDay: RoutineDay? {
        let liftingDays = allDays.filter { $0.kind == .lifting }.sorted { $0.position < $1.position }
        guard !liftingDays.isEmpty else { return nil }

        let lastCompleted = allSessions
            .filter { session in
                guard let day = session.routineDay, day.kind == .lifting else { return false }
                return !session.loggedSets.isEmpty
            }
            .sorted { $0.sessionDate > $1.sessionDate }
            .first

        guard
            let lastDay = lastCompleted?.routineDay,
            let lastIndex = liftingDays.firstIndex(where: { $0.id == lastDay.id })
        else {
            return liftingDays.first
        }
        return liftingDays[(lastIndex + 1) % liftingDays.count]
    }

    private var todaySession: WorkoutSession? {
        allSessions.first { Calendar.current.isDate($0.sessionDate, inSameDayAs: .now) }
    }

    private var streakResult: StreakCalculator.Result {
        let activeDates = allSessions
            .filter { !$0.loggedSets.isEmpty || ($0.cardioMinutes ?? 0) > 0 }
            .map(\.sessionDate)
        return StreakCalculator.compute(activeDays: activeDates)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppMetrics.spacing) {
                    dateHeader
                    streakCard

                    if allDays.isEmpty {
                        Text("Nenhum treino cadastrado ainda. Toque em sincronizar ou confira a aba Rotina.")
                            .foregroundStyle(AppColor.textSecondary)
                            .padding()
                    } else {
                        if let liftingDay = nextLiftingDay {
                            SectionHeaderLabel(text: "Próximo treino")
                            liftingCard(liftingDay)
                        }

                        if let schedule = todaySchedule, let cardioType = schedule.cardioType {
                            SectionHeaderLabel(text: "Cardio de hoje")
                                .padding(.top, 4)
                            cardioCard(day: schedule, type: cardioType)
                        }
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

    private var dateHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Date().formatted(.dateTime.weekday(.wide).day().month(.wide)).uppercased())
                .font(AppFont.caption(12))
                .foregroundStyle(AppColor.textSecondary)
            Text("Hoje")
                .font(AppFont.largeTitle(28))
                .foregroundStyle(AppColor.textPrimary)
        }
    }

    private var streakCard: some View {
        let result = streakResult
        return HStack(spacing: 16) {
            VStack(spacing: 2) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(AppColor.strength)
                Text("\(result.current)")
                    .font(AppFont.numeric(22, weight: .bold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(result.current == 1 ? "dia" : "dias")
                    .font(AppFont.caption(11))
                    .foregroundStyle(AppColor.textSecondary)
            }
            .frame(width: 60)

            Rectangle()
                .fill(AppColor.textSecondary.opacity(0.25))
                .frame(width: 1, height: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(result.trainedToday ? "Treino de hoje registrado 🔥" : "Treine hoje pra manter sua streak")
                    .font(AppFont.body(13))
                    .foregroundStyle(AppColor.textPrimary)
                Text("Recorde: \(result.longest) dia\(result.longest == 1 ? "" : "s")")
                    .font(AppFont.caption(12))
                    .foregroundStyle(AppColor.textSecondary)
            }
            Spacer()
        }
        .cardStyle()
    }

    private func liftingCard(_ day: RoutineDay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(day.name)
                        .font(AppFont.title(22))
                        .foregroundStyle(AppColor.textPrimary)
                    Text("Treino \(day.position) de 4 na sequência")
                        .font(AppFont.caption(12))
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer()
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColor.strength)
                    .padding(12)
                    .background(AppColor.strength.opacity(0.16), in: Circle())
            }

            VStack(spacing: 10) {
                ForEach(day.exercises.sorted(by: { $0.position < $1.position })) { re in
                    exerciseRow(re)
                }
            }
        }
        .cardStyle()
    }

    private func exerciseRow(_ re: RoutineExercise) -> some View {
        let loggedCount = todaySession?.loggedSets.filter { $0.exercise?.id == re.exercise?.id }.count ?? 0
        return Button {
            addSetTarget = re
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(re.exercise?.name ?? "—")
                        .font(AppFont.headline(15))
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
                    .font(.system(size: 20))
                    .foregroundStyle(AppColor.strength)
            }
            .padding(10)
            .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppMetrics.smallCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
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
        let session = WorkoutSession(routineDay: nextLiftingDay, sessionDate: .now, startedAt: .now)
        context.insert(session)
        try? context.save()
        return session
    }
}
