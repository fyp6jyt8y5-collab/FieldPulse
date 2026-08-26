import SwiftUI
import WatchKit

@main
struct FieldPulseWatchApp: App {
    @StateObject private var location = LocationService()
    @StateObject private var weather = WeatherService()
    @StateObject private var connectivity = ConnectivityService()

    var body: some Scene {
        WindowGroup {
            WatchDashboardView()
                .environmentObject(location)
                .environmentObject(weather)
                .environmentObject(connectivity)
                .task { location.requestPermissionAndStart() }
                .onReceive(location.$location.compactMap { $0 }) { value in Task { await weather.refresh(for: value) } }
        }
    }
}
