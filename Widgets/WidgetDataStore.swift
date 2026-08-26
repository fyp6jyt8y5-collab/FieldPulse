import Foundation
import WidgetKit

@MainActor
final class WidgetDataStore {
    static let shared = WidgetDataStore()
    private init() {}

    func save(_ value: AppData) {
        SharedDataStore.save(value)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
