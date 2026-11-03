import Foundation

extension Date {
    /// 1 = Segunda ... 7 = Domingo (diferente do Calendar padrão, que usa 1 = Domingo)
    var isoWeekday: Int {
        let calendarWeekday = Calendar.current.component(.weekday, from: self) // 1=Dom...7=Sáb
        return calendarWeekday == 1 ? 7 : calendarWeekday - 1
    }
}
