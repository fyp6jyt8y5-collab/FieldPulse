import SwiftUI
import CoreLocation

struct DashboardView: View {
    @EnvironmentObject private var location: LocationService
    @EnvironmentObject private var weather: WeatherService
    @EnvironmentObject private var connectivity: ConnectivityService

    var body: some View {
        NavigationStack {
            List {
                Section("Now") {
                    if let current = weather.current {
                        Label(current.temperature.formatted(), systemImage: current.symbolName)
                            .font(.title2.bold())
                        Text(current.condition.description)
                        if let city = location.placemark?.locality { Label(city, systemImage: "location.fill") }
                    } else { ContentUnavailableView("Weather unavailable", systemImage: "cloud.slash") }
                }
                Section("Location") {
                    metric("Coordinates", value: coordinates)
                    metric("Altitude", value: location.location.map { $0.altitude.formatted(.number.precision(.fractionLength(0))) + " m" } ?? "--")
                    metric("Accuracy", value: location.location.map { $0.horizontalAccuracy.formatted(.number.precision(.fractionLength(0))) + " m" } ?? "--")
                    metric("Country", value: location.placemark?.country ?? "--")
                }
                Section("Devices") {
                    metric("Watch battery", value: connectivity.data.watchBattery.map { $0.formatted(.percent) } ?? "--")
                    metric("iPhone battery", value: connectivity.data.phoneBattery.map { $0.formatted(.percent) } ?? "--")
                    Label(connectivity.isReachable ? "Watch connected" : "Watch unavailable", systemImage: connectivity.isReachable ? "applewatch.radiowaves.left.and.right" : "applewatch.slash")
                }
                Section("Permissions") {
                    Label(permissionText, systemImage: permissionSymbol)
                    Button("Update location") { location.requestPermissionAndStart() }
                }
                Section("PC control") {
                    NavigationLink {
                        HeadMouseView()
                    } label: {
                        Label("Head Mouse", systemImage: "dot.scope")
                    }
                    NavigationLink {
                        RemoteScreenView()
                    } label: {
                        Label("Remote Screen", systemImage: "rectangle.inset.filled")
                    }
                }
                if let error = location.errorMessage ?? weather.errorMessage { Section { Text(error).foregroundStyle(.red) } }
            }
            .navigationTitle("FieldPulse")
            .refreshable { if let value = location.location { await weather.refresh(for: value) } }
        }
    }

    private var coordinates: String { guard let value = location.location else { return "--" }; return "\(value.coordinate.latitude.formatted(.number.precision(.fractionLength(4)))), \(value.coordinate.longitude.formatted(.number.precision(.fractionLength(4))))" }
    private var permissionText: String { switch location.authorization { case .authorizedAlways, .authorizedWhenInUse: return "Location allowed"; case .denied, .restricted: return "Location denied"; default: return "Location permission needed" } }
    private var permissionSymbol: String { location.authorization == .denied || location.authorization == .restricted ? "location.slash" : "location" }
    private func metric(_ title: String, value: String) -> some View { LabeledContent(title, value: value) }
}

private extension Measurement where UnitType == UnitTemperature { func formatted() -> String { formatted(.measurement(width: .abbreviated, usage: .weather)) } }
