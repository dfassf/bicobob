import Foundation

struct DayMenu: Codable, Identifiable {
    var id: String { day }
    let day: String
    let lunch: [String]
    let dinner: [String]
}

/// 백오피스 GET /api/public/lunch-menu 응답.
struct WeeklyMenuResponse: Codable {
    let weekStartDate: String
    let menus: [DayMenu]
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case weekStartDate = "week_start_date"
        case menus
        case updatedAt = "updated_at"
    }
}

struct WeeklyMenuCache: Codable {
    let cachedAt: String
    let weekKey: String
    let menus: [DayMenu]
}

struct AppSettings: Codable {
    var notifyEnabled: Bool
    var notifyTime: String
    var showOnStartup: Bool
    var launchAtLogin: Bool
    var darkMode: Bool

    static let `default` = AppSettings(
        notifyEnabled: true,
        notifyTime: "12:35",
        showOnStartup: true,
        launchAtLogin: false,
        darkMode: true
    )

    init(notifyEnabled: Bool, notifyTime: String, showOnStartup: Bool, launchAtLogin: Bool, darkMode: Bool) {
        self.notifyEnabled = notifyEnabled
        self.notifyTime = notifyTime
        self.showOnStartup = showOnStartup
        self.launchAtLogin = launchAtLogin
        self.darkMode = darkMode
    }

    // 새 필드(darkMode)가 추가돼도 기존 저장값을 깨뜨리지 않도록 누락 필드는 기본값으로
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = AppSettings.default
        notifyEnabled = try c.decodeIfPresent(Bool.self, forKey: .notifyEnabled) ?? d.notifyEnabled
        notifyTime = try c.decodeIfPresent(String.self, forKey: .notifyTime) ?? d.notifyTime
        showOnStartup = try c.decodeIfPresent(Bool.self, forKey: .showOnStartup) ?? d.showOnStartup
        launchAtLogin = try c.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? d.launchAtLogin
        darkMode = try c.decodeIfPresent(Bool.self, forKey: .darkMode) ?? d.darkMode
    }
}
