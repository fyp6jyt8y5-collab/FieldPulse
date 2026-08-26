import SwiftUI

@main
struct FieldPulseApp: App {
    @StateObject private var location = LocationService()
    @StateObject private var weather = WeatherService()
    @StateObject private var connectivity = ConnectivityService()

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(location)
                .environmentObject(weather)
                .environmentObject(connectivity)
                .task { location.requestPermissionAndStart() }
                .onReceive(location.$location.compactMap { $0 }) { value in
                    Task {
                        await weather.refresh(for: value)
                        syncData()
                    }
                }
        }
    }

    private func syncData() {
        let coordinate = location.location?.coordinate
        let current = weather.current
        var value = AppData.empty
        value.latitude = coordinate?.latitude
        value.longitude = coordinate?.longitude
        value.altitude = location.location?.altitude
        value.accuracy = location.location?.horizontalAccuracy
        value.city = location.placemark?.locality
        value.country = location.placemark?.country
        value.temperature = current?.temperature.value
        value.feelsLike = current?.apparentTemperature.value
        value.condition = current?.condition.description
        value.humidity = current?.humidity
        value.windSpeed = current?.wind.speed.value
        value.windDirection = current?.wind.direction.value
        value.updatedAt = .now
        value.phoneBattery = UIDevice.current.batteryLevel >= 0 ? Double(UIDevice.current.batteryLevel) : nil
        value.phoneReachable = connectivity.isReachable
        connectivity.send(value)
    }
}
