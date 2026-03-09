import Foundation

enum SettingsService {
    private static let key = "app_settings"

    static func load() -> AppSettings {
        // First try UserDefaults
        if let data = UserDefaults.standard.data(forKey: key),
           let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            return settings
        }

        // Fallback to .env file
        return loadFromEnv()
    }

    static func save(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private static func loadFromEnv() -> AppSettings {
        var env: [String: String] = [:]

        // Check multiple possible .env locations
        let paths = [
            Bundle.main.bundlePath + "/../.env",
            FileManager.default.currentDirectoryPath + "/.env",
            NSHomeDirectory() + "/Desktop/prv/bicobob/.env",
        ]

        for path in paths {
            if let content = try? String(contentsOfFile: path, encoding: .utf8) {
                for line in content.components(separatedBy: .newlines) {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }
                    let parts = trimmed.split(separator: "=", maxSplits: 1)
                    if parts.count == 2 {
                        env[String(parts[0])] = String(parts[1])
                    }
                }
                break
            }
        }

        return AppSettings(
            slackToken: env["SLACK_TOKEN"] ?? "",
            channelName: env["CHANNEL_NAME"] ?? "",
            username: env["USERNAME"] ?? "",
            geminiApiKey: env["GEMINI_API_KEY"] ?? "",
            notifyEnabled: true,
            notifyTime: "12:35",
            showOnStartup: true,
            launchAtLogin: false
        )
    }
}
