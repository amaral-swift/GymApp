import Foundation

/// Calcula a streak de treinos a partir dos dias com atividade registrada.
/// Regra: permite 1 dia de intervalo sem quebrar a streak (pra não punir um feriado,
/// imprevisto, etc. — exatamente o caso que gerou essa função). Dois dias seguidos sem
/// nada registrado quebram a streak. O dia de hoje nunca quebra a streak antes da hora:
/// se ainda não tem nada registrado hoje, a contagem considera a partir de ontem.
enum StreakCalculator {
    struct Result {
        let current: Int
        let longest: Int
        let trainedToday: Bool
    }

    static func compute(activeDays: [Date], now: Date = .now, calendar: Calendar = .current) -> Result {
        let days = Set(activeDays.map { calendar.startOfDay(for: $0) })
        let today = calendar.startOfDay(for: now)

        let trainedToday = days.contains(today)
        var current = trainedToday ? 1 : 0
        var cursor = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        var graceUsed = false
        var safety = 0

        while safety < 2000 {
            safety += 1
            if days.contains(cursor) {
                current += 1
                cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
            } else if !graceUsed {
                graceUsed = true
                cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
            } else {
                break
            }
        }

        let longest = longestStreak(days: days, calendar: calendar)
        return Result(current: current, longest: max(longest, current), trainedToday: trainedToday)
    }

    private static func longestStreak(days: Set<Date>, calendar: Calendar) -> Int {
        guard !days.isEmpty else { return 0 }
        let sorted = days.sorted()
        var best = 1
        for i in 0..<sorted.count {
            var run = 1
            var graceUsed = false
            var j = i
            while j + 1 < sorted.count {
                let plusOne = calendar.date(byAdding: .day, value: 1, to: sorted[j]) ?? sorted[j]
                let plusTwo = calendar.date(byAdding: .day, value: 2, to: sorted[j]) ?? sorted[j]
                if sorted[j + 1] == plusOne {
                    run += 1
                    j += 1
                } else if sorted[j + 1] == plusTwo && !graceUsed {
                    graceUsed = true
                    run += 1
                    j += 1
                } else {
                    break
                }
            }
            best = max(best, run)
        }
        return best
    }
}
