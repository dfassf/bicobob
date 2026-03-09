import Foundation

struct DayMenu: Codable, Identifiable {
    var id: String { day }
    let day: String
    let lunch: [String]
    let dinner: [String]
}

struct WeeklyMenuCache: Codable {
    let slackTs: String
    let cachedAt: String
    let weekKey: String
    let menus: [DayMenu]
    let imageBase64: String
    let messageText: String
}

struct AppSettings: Codable {
    var slackToken: String
    var channelName: String
    var username: String
    var geminiApiKey: String
    var notifyEnabled: Bool
    var notifyTime: String
    var showOnStartup: Bool
    var launchAtLogin: Bool

    static let `default` = AppSettings(
        slackToken: "",
        channelName: "",
        username: "",
        geminiApiKey: "",
        notifyEnabled: true,
        notifyTime: "12:35",
        showOnStartup: true,
        launchAtLogin: false
    )
}

struct LunchImage {
    let base64DataUrl: String
    let filename: String
    let timestamp: String
    let messageText: String
}
