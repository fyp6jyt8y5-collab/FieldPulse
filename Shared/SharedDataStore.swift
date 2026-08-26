import Foundation

struct SharedDataStore {
    static let suiteName = "group.com.example.fieldpulse"
    static let dataKey = "latestAppData"

    static func save(_ value: AppData) {
        guard let encoded = try? JSONEncoder().encode(value), let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.set(encoded, forKey: dataKey)
    }

    static func load() -> AppData {
        guard let defaults = UserDefaults(suiteName: suiteName), let encoded = defaults.data(forKey: dataKey), let value = try? JSONDecoder().decode(AppData.self, from: encoded) else { return .empty }
        return value
    }
}
