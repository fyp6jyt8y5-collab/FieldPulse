import Foundation
import Combine
import WeatherKit
import CoreLocation

@MainActor
final class WeatherService: ObservableObject {
    @Published private(set) var weather: Weather?
    @Published private(set) var errorMessage: String?
    private let service = WeatherServiceAPI()

    func refresh(for location: CLLocation) async {
        do { weather = try await service.weather(for: location); errorMessage = nil }
        catch { errorMessage = "Weather is unavailable right now." }
    }

    var current: CurrentWeather? { weather?.currentWeather }
    var daily: Forecast<DayWeather>? { weather?.dailyForecast }
    var hourly: Forecast<HourWeather>? { weather?.hourlyForecast }
}

private struct WeatherServiceAPI {
    func weather(for location: CLLocation) async throws -> Weather { try await WeatherKit.WeatherService.shared.weather(for: location) }
}
