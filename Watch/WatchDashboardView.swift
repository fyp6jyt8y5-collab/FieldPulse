import SwiftUI
import WatchKit

struct WatchDashboardView: View {
    @EnvironmentObject private var location: LocationService
    @EnvironmentObject private var weather: WeatherService
    @EnvironmentObject private var connectivity: ConnectivityService
    @State private var battery = WKInterfaceDevice.current().batteryLevel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(Date.now, format: .dateTime.weekday(.wide).day().month(.abbreviated))
                    .font(.caption).foregroundStyle(.secondary)
                Text(Date.now, format: .dateTime.hour().minute())
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                if let current = weather.current {
                    Label(current.temperature.formatted(.measurement(width: .abbreviated, usage: .weather)), systemImage: current.symbolName).font(.title3.bold())
                    Text(current.condition.description).font(.caption)
                } else { Label("Weather unavailable", systemImage: "cloud.slash") }
                Divider()
                Label(location.placemark?.locality ?? "Unknown location", systemImage: "location.fill")
                Label("Watch \((battery * 100).formatted(.number.precision(.fractionLength(0))))%", systemImage: "battery.100")
                Label(connectivity.data.phoneBattery.map { "iPhone \(($0 * 100).formatted(.number.precision(.fractionLength(0))))%" } ?? "iPhone unavailable", systemImage: "iphone")
                Label(connectivity.isReachable ? "Connected" : "Independent mode", systemImage: connectivity.isReachable ? "checkmark.circle" : "wifi.slash")
            }
            .padding(.horizontal)
        }
        .task { WKInterfaceDevice.current().isBatteryMonitoringEnabled = true; battery = WKInterfaceDevice.current().batteryLevel }
    }
}
