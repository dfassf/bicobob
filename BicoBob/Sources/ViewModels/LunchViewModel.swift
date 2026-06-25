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
        let weekKey = DateUtils.currentWeekKey()

        // 최근 3분 내 같은 주를 이미 받아왔으면 스킵
        if let currentCache = cache, currentCache.weekKey == weekKey,
           Date().timeIntervalSince(lastCheckTime) < 180 {
            return
        }

        status = .fetching
        self.error = nil

        do {
            lastCheckTime = Date()
            let response = try await MenuAPIService.fetchWeeklyMenu()  // 이번 주(백엔드 KST 기준)

            let newCache = WeeklyMenuCache(
                cachedAt: ISO8601DateFormatter().string(from: Date()),
                weekKey: weekKey,
                menus: response.menus
            )

            CacheService.saveCache(weekKey: weekKey, cache: newCache)
            cache = newCache
            status = .done
        } catch {
            // 네트워크 실패 시 캐시라도 보여준다
            if let cached = CacheService.loadCurrentCache() {
                cache = cached
                status = .done
            } else {
                self.error = error.localizedDescription
                status = .error
            }
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
