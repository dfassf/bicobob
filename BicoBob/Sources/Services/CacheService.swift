import Foundation

enum CacheService {
    private static var cacheFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("BicoBob", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("menu-cache.json")
    }

    static func loadCacheMap() -> [String: WeeklyMenuCache] {
        guard let data = try? Data(contentsOf: cacheFileURL),
              let map = try? JSONDecoder().decode([String: WeeklyMenuCache].self, from: data) else {
            return [:]
        }
        return map
    }

    static func saveCache(weekKey: String, cache: WeeklyMenuCache) {
        var map = loadCacheMap()
        map[weekKey] = cache

        // Keep only current and next week
        let thisWeek = DateUtils.currentWeekKey()
        let validKeys = Set([thisWeek])
        for key in map.keys where !validKeys.contains(key) {
            map.removeValue(forKey: key)
        }

        guard let data = try? JSONEncoder().encode(map) else { return }
        try? data.write(to: cacheFileURL)
    }

    static func loadCurrentCache() -> WeeklyMenuCache? {
        let weekKey = DateUtils.currentWeekKey()
        return loadCacheMap()[weekKey]
    }
}
