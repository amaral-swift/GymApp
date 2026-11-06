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
    /// Escolha manual de qual treino fazer hoje, feita ANTES de iniciar o treino.
    /// Depois que o treino é iniciado, quem manda é a sessão de hoje (`todayLiftingSession`),
    /// não isso aqui — assim a tela não pula pro próximo treino da sequência no meio do treino
    /// só porque você registrou uma série.
    @State private var manualLiftingDayID: UUID?

    private var liftingDays: [RoutineDay] {
        allDays.filter { $0.kind == .lifting }.sorted { $0.position < $1.position }
    }

    /// Dia de referência do calendário (pra corrida/pedal, que ficam fixos em dias certos).
    private var todaySchedule: RoutineDay? {
        allDays.first { $0.weekday == Date().isoWeekday }
    }

    /// Sugestão de próximo treino de musculação na sequência (Superior A → Inferior A → Superior B → Inferior B),
    /// baseada no último treino concluído — não no dia da semana. Só é usada ANTES de iniciar o treino de hoje;
    /// uma vez iniciado, a sessão de hoje já diz qual é o treino, e essa sugestão para de importar até o dia seguinte.
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

    /// Sessão de musculação de HOJE, se o treino já tiver sido iniciado — uma por dia, no máximo.
    /// Uma vez que ela existe, o treino de hoje é esse e pronto, não importa quantas séries
    /// já foram registradas nela.
    private var todayLiftingSession: WorkoutSession? {
        allSessions.first {
            Calendar.current.isDate($0.sessionDate, inSameDayAs: .now) && $0.routineDay?.kind == .lifting
        }
    }

    private var hasStartedToday: Bool { todayLiftingSession != nil }

    /// O treino de musculação ativo na tela: se já foi iniciado hoje, é sempre o mesmo (não muda mais);
    /// senão, é a escolha manual (se houver) ou a sugestão.
    private var activeLiftingDay: RoutineDay? {
        if let started = todayLiftingSession?.routineDay {
            return started
        }
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

    /// Cria a sessão de hoje pro treino certo só quando realmente precisa (ao iniciar o treino,
    /// registrar uma série ou salvar o cardio) — nunca só por abrir a tela, pra não deixar
    /// sessões vazias no histórico.
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
                VStack(alignment: .leading, spacing: 10) {
                    dateHeader
                        .padding(.bottom, 6)

                    if allDays.isEmpty {
                        Text("Nenhum treino cadastrado ainda. Toque em sincronizar ou confira a aba Rotina.")
                            .foregroundStyle(AppColor.textSecondary)
                            .padding()
                    } else {
                        if !liftingDays.isEmpty {
                            if hasStartedToday, let day = activeLiftingDay {
                                liftingCard(day)
                                if canCancelTodayWorkout {
                                    cancelWorkoutButton
                                }
                            } else if let day = activeLiftingDay {
                                liftingPreviewCard(day)
                            }
                        }

                        if let schedule = todaySchedule, let cardioType = schedule.cardioType {
                            SectionHeaderLabel(text: "Cardio de hoje")
                                .padding(.top, 4)
                            cardioCard(day: schedule, type: cardioType)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .screenBackground()
            .navigationTitle("")
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
        VStack(alignment: .leading, spacing: 2) {
            Text(Date().formatted(.dateTime.weekday(.wide).day().month(.wide)).uppercased())
                .font(AppFont.caption(12))
                .foregroundStyle(AppColor.textSecondary)
            HStack(alignment: .center) {
                Text("Hoje")
                    .font(AppFont.largeTitle(28))
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(AppColor.strength)
                    Text("\(streakResult.current)")
                        .font(AppFont.numeric(18, weight: .bold))
                        .foregroundStyle(AppColor.textPrimary)
                }
            }
        }
    }

    /// Seletor horizontal dos 4 treinos de musculação, pra escolher manualmente qual fazer hoje
    /// quando a sugestão automática não bater com o que você quer treinar. Só aparece antes de
    /// iniciar o treino — depois de iniciado, o treino de hoje já está decidido.
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

    /// Botão que de fato começa o treino de hoje: cria a sessão pro dia escolhido/sugerido.
    /// A partir daqui esse é o treino do dia, até virar a data.
    private func startWorkoutButton(for day: RoutineDay) -> some View {
        Button {
            findOrCreateSession(for: day)
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("Iniciar treino: \(day.name)")
            }
            .font(AppFont.headline(15).weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppColor.strength, in: RoundedRectangle(cornerRadius: AppMetrics.smallCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    /// Só é possível trocar o treino de hoje enquanto nenhuma série foi registrada ainda —
    /// depois disso, apagar mudaria dados reais, então a troca passa a ser pelo Histórico.
    private var canCancelTodayWorkout: Bool {
        guard let session = todayLiftingSession else { return false }
        return session.loggedSets.isEmpty
    }

    private var cancelWorkoutButton: some View {
        Button {
            if let session = todayLiftingSession {
                Task { await syncService.deleteSession(session, context: context) }
            }
        } label: {
            Text("Troquei de ideia, escolher outro treino")
                .font(AppFont.caption(13))
                .foregroundStyle(AppColor.textSecondary)
                .underline()
        }
        .buttonStyle(.plain)
    }

    /// Card de pré-visualização do treino antes de iniciar: mostra o seletor de treino,
    /// a lista de exercícios (só pra visualizar, não dá pra registrar série ainda) e o botão
    /// pra iniciar de fato. Substitui o card vazio que ficava só com o seletor.
    private func liftingPreviewCard(_ day: RoutineDay) -> some View {
        VStack(alignment: .leading, spacing: 14) {
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

            daySwitcher

            VStack(spacing: 10) {
                ForEach(day.exercises.sorted(by: { $0.position < $1.position })) { re in
                    exercisePreviewRow(re)
                }
            }

            startWorkoutButton(for: day)
        }
        .cardStyle()
    }

    private func exercisePreviewRow(_ re: RoutineExercise) -> some View {
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
        }
        .padding(10)
        .background(AppColor.surfaceElevated.opacity(0.6), in: RoundedRectangle(cornerRadius: AppMetrics.smallCornerRadius, style: .continuous))
    }

    private func liftingCard(_ day: RoutineDay) -> some View {
        let session = existingSession(for: day)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(day.name)
                        .font(AppFont.title(22))
                        .foregroundStyle(AppColor.textPrimary)
                    Text("Treino de hoje · posição \(day.position) de 4 na sequência")
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
