import Foundation

enum DateUtils {
    private static let kst = TimeZone(identifier: "Asia/Seoul")!
    private static let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
    private static let weekLabels = ["", "첫째주", "둘째주", "셋째주", "넷째주", "다섯째주"]

    static func nowKST() -> Date {
        Date()
    }

    static func kstComponents(_ date: Date = Date()) -> DateComponents {
        Calendar.current.dateComponents(in: kst, from: date)
    }

    static func dateByOffset(_ offset: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: Date())!
    }

    static func weekdayName(offset: Int) -> String {
        let comps = kstComponents(dateByOffset(offset))
        return weekdays[comps.weekday! - 1]
    }

    static func isWeekend(offset: Int) -> Bool {
        let day = weekdayName(offset: offset)
        return day == "토" || day == "일"
    }

    static func dateString(offset: Int = 0) -> String {
        let date = dateByOffset(offset)
        let comps = kstComponents(date)
        let day = weekdays[comps.weekday! - 1]
        return String(format: "%04d.%02d.%02d (%@)", comps.year!, comps.month!, comps.day!, day)
    }

    static func currentWeekKey() -> String {
        let comps = kstComponents()
        let weekNum = min(((comps.day! - 1) / 7) + 1, 5)
        return "\(comps.month!)월 \(weekLabels[weekNum])"
    }

    static func timeString() -> String {
        let comps = kstComponents()
        return String(format: "%02d:%02d", comps.hour!, comps.minute!)
    }
}
