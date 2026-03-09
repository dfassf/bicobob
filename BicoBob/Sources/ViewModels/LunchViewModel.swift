import Foundation
import SwiftUI

enum LoadingStatus {
    case idle, fetching, analyzing, done, error
}

@MainActor
class LunchViewModel: ObservableObject {
    @Published var settings: AppSettings
    @Published var cache: WeeklyMenuCache?
    @Published var status: LoadingStatus = .idle
    @Published var error: String?
    @Published var dayOffset: Int = 0

    private var lastCheckTime: Date = .distantPast

    var currentDay: String {
        DateUtils.weekdayName(offset: dayOffset)
    }

    var todayMenu: DayMenu? {
        cache?.menus.first(where: { $0.day == currentDay })
    }

    var isWeekendDay: Bool {
        DateUtils.isWeekend(offset: dayOffset)
    }

    var dateString: String {
        DateUtils.dateString(offset: dayOffset)
    }

    var canGoPrev: Bool {
        canNavigate(direction: -1)
    }

    var canGoNext: Bool {
        canNavigate(direction: 1)
    }

    init() {
        self.settings = SettingsService.load()
        self.cache = CacheService.loadCurrentCache()
        if cache != nil { status = .done }
    }

    func refresh() async {
        guard !settings.slackToken.isEmpty else {
            error = "Slack 토큰이 설정되지 않았습니다."
            status = .error
            return
        }

        let weekKey = DateUtils.currentWeekKey()

        // Cache hit + ts check (within 3 min = skip)
        if let currentCache = cache, currentCache.weekKey == weekKey {
            if Date().timeIntervalSince(lastCheckTime) < 180 {
                return
            }
            do {
                lastCheckTime = Date()
                let latestTs = try await SlackService.checkMessageTs(
                    token: settings.slackToken,
                    channelName: settings.channelName,
                    username: settings.username
                )
                if let ts = latestTs, ts == currentCache.slackTs {
                    status = .done
                    return
                }
            } catch {
                // Fall through to full fetch
            }
        }

        status = .fetching
        self.error = nil

        do {
            let images = try await SlackService.fetchLunchImages(
                token: settings.slackToken,
                channelName: settings.channelName,
                username: settings.username
            )

            guard !images.isEmpty else {
                if let cached = CacheService.loadCurrentCache() {
                    cache = cached
                    status = .done
                    return
                }
                throw AppError.noMenu
            }

            let msgText = images[0].messageText
            guard msgText.contains(weekKey) else {
                if let cached = CacheService.loadCurrentCache() {
                    cache = cached
                    status = .done
                    return
                }
                throw AppError.noMenu
            }

            guard !settings.geminiApiKey.isEmpty else {
                throw AppError.gemini("Gemini API Key가 설정되지 않았습니다.")
            }

            status = .analyzing
            let menus = try await GeminiService.analyzeMenu(
                imageBase64: images[0].base64DataUrl,
                apiKey: settings.geminiApiKey
            )

            let newCache = WeeklyMenuCache(
                slackTs: images[0].timestamp,
                cachedAt: ISO8601DateFormatter().string(from: Date()),
                weekKey: weekKey,
                menus: menus,
                imageBase64: images[0].base64DataUrl,
                messageText: images[0].messageText
            )

            CacheService.saveCache(weekKey: weekKey, cache: newCache)
            cache = newCache
            status = .done
        } catch {
            self.error = error.localizedDescription
            status = .error
        }
    }

    func navigateDay(_ direction: Int) {
        var next = dayOffset + direction
        let nextDay = DateUtils.weekdayName(offset: next)
        if nextDay == "토" { next += direction > 0 ? 2 : -1 }
        else if nextDay == "일" { next += direction > 0 ? 1 : -2 }
        dayOffset = next
    }

    func saveSettings() {
        SettingsService.save(settings)
    }

    private func canNavigate(direction: Int) -> Bool {
        let availableDays = cache?.menus.map(\.day) ?? []
        var testOffset = dayOffset + direction
        for _ in 0..<7 {
            let day = DateUtils.weekdayName(offset: testOffset)
            if day == "토" || day == "일" {
                testOffset += direction
                continue
            }
            return availableDays.contains(day)
        }
        return false
    }
}
