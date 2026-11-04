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
    /// Quando o usuário escolhe manualmente qual treino de musculação está fazendo hoje,
    /// substituindo a sugestão automática. Fica só na memória (não precisa persistir).
    @State private var manualLiftingDayID: UUID?

    private var liftingDays: [RoutineDay] {
        allDays.filter { $0.kind == .lifting }.sorted { $0.position < $1.position }
    }

    /// Dia de referência do calendário (pra corrida/pedal, que ficam fixos em dias certos).
    private var todaySchedule: RoutineDay? {
        allDays.first { $0.weekday == Date().isoWeekday }
    }

    /// Sugestão de próximo treino de musculação na sequência (Superior A → Inferior A → Superior B → Inferior B),
    /// baseada no último treino concluído — não no dia da semana. Assim, se você pula um dia,
    /// a sugestão continua de onde parou, em vez de pular pro "treino do dia" seguinte.
    /// É só uma sugestão: o usuário pode trocar no seletor de treino abaixo.
    private var suggestedLiftingDay: RoutineDay? {
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

    /// O treino de musculação que está ativo na tela agora: a escolha manual, se houver, senão a sugestão.
    private var activeLiftingDay: RoutineDay? {
        if let manualLiftingDayID, let match = liftingDays.first(where: { $0.id == manualLiftingDayID }) {
            return match
        }
        return suggestedLiftingDay
    }

    private var streakResult: StreakCalculator.Result {
        let activeDates = allSessions
            .filter { !$0.loggedSets.isEmpty || ($0.cardioMinutes ?? 0) > 0 }
            .map(\.sessionDate)
        return StreakCalculator.compute(activeDays: activeDates)
    }

    /// Sessão de HOJE pra um treino específico (musculação ou cardio) — nunca é criada aqui,
    /// só procurada. Cada treino do dia tem a sua própria sessão, então cardio e musculação
    /// no mesmo dia não se misturam.
    private func existingSession(for day: RoutineDay?) -> WorkoutSession? {
        guard let day else { return nil }
        return allSessions.first {
            Calendar.current.isDate($0.sessionDate, inSameDayAs: .now) && $0.routineDay?.id == day.id
        }
    }

    /// Cria a sessão de hoje pro treino certo só quando realmente precisa (ao salvar uma série ou o cardio) —
    /// nunca ao simplesmente abrir a tela ou o formulário, pra não deixar sessões vazias no histórico.
    @discardableResult
    private func findOrCreateSession(for day: RoutineDay?) -> WorkoutSession {
        if let existing = existingSession(for: day) { return existing }
        let session = WorkoutSession(routineDay: day, sessionDate: .now, startedAt: .now)
        context.insert(session)
        try? context.save()
        return session
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
                        if !liftingDays.isEmpty {
                            SectionHeaderLabel(text: "Próximo treino")
                            daySwitcher
                            if let day = activeLiftingDay {
                                liftingCard(day)
                            }
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
                AddSetSheet(
                    routineExercise: re,
                    existingSession: existingSession(for: activeLiftingDay),
                    resolveSession: { findOrCreateSession(for: activeLiftingDay) }
                )
            }
            .onAppear {
                if let existing = existingSession(for: todaySchedule)?.cardioMinutes {
                    cardioMinutesText = String(existing)
                }
            }
        }
    }

    private var dateHeader: some View {
        Text(Date().formatted(.dateTime.weekday(.wide).day().month(.wide)).uppercased())
            .font(AppFont.caption(12))
            .foregroundStyle(AppColor.textSecondary)
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

    /// Seletor horizontal dos 4 treinos de musculação, pra escolher manualmente qual fazer hoje
    /// quando a sugestão automática não bater com o que você quer treinar.
    private var daySwitcher: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Qual treino você vai fazer hoje?")
                .font(AppFont.caption(12))
                .foregroundStyle(AppColor.textSecondary)
            HStack(spacing: 8) {
                ForEach(liftingDays) { day in
                    let isActive = activeLiftingDay?.id == day.id
                    Button {
                        manualLiftingDayID = day.id
                    } label: {
                        Text(day.name)
                            .font(AppFont.caption(12).weight(isActive ? .bold : .regular))
                            .foregroundStyle(isActive ? AppColor.strength : AppColor.textSecondary)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                isActive ? AppColor.strength.opacity(0.18) : AppColor.surfaceElevated,
                                in: RoundedRectangle(cornerRadius: AppMetrics.smallCornerRadius, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func liftingCard(_ day: RoutineDay) -> some View {
        let session = existingSession(for: day)
        let isManualOverride = manualLiftingDayID != nil && day.id != suggestedLiftingDay?.id
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(day.name)
                        .font(AppFont.title(22))
                        .foregroundStyle(AppColor.textPrimary)
                    Text(isManualOverride
                         ? "Escolhido manualmente · a sequência continua a partir daqui"
                         : "Treino \(day.position) de 4 na sequência")
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
                    exerciseRow(re, session: session)
                }
            }
        }
        .cardStyle()
    }

    private func exerciseRow(_ re: RoutineExercise, session: WorkoutSession?) -> some View {
        let loggedCount = session?.loggedSets.filter { $0.exercise?.id == re.exercise?.id }.count ?? 0
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
                Button("Salvar") { saveCardio(day: day, type: type) }
                    .font(AppFont.caption(13).weight(.bold))
                    .foregroundStyle(AppColor.cardio)
            }
        }
        .cardStyle()
    }

    private func saveCardio(day: RoutineDay, type: String) {
        let session = findOrCreateSession(for: day)
        session.cardioType = type
        session.cardioMinutes = Int(cardioMinutesText)
        session.needsSync = true
        try? context.save()
    }
}
