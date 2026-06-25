import AppKit
import Foundation

extension Notification.Name {
    /// 다크/라이트 설정이 바뀌었을 때 — 패널이 외관을 다시 적용하도록.
    static let bicoAppearanceChanged = Notification.Name("BicoBobAppearanceChanged")
}

enum SettingsService {
    private static let key = "app_settings"

    static func load() -> AppSettings {
        // Try UserDefaults as Data
        if let data = UserDefaults.standard.data(forKey: key),
           let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            return settings
        }

        // Try UserDefaults as String (e.g. written via defaults command)
        if let str = UserDefaults.standard.string(forKey: key),
           let data = str.data(using: .utf8),
           let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            return settings
        }

        return .default
    }

    static func save(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
