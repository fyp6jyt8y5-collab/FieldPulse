import Foundation

struct AppData: Codable, Sendable {
    var latitude: Double?
    var longitude: Double?
    var altitude: Double?
    var accuracy: Double?
    var city: String?
    var country: String?
    var temperature: Double?
    var feelsLike: Double?
    var condition: String?
    var humidity: Double?
    var windSpeed: Double?
    var windDirection: Double?
    var rainChance: Double?
    var updatedAt: Date?
    var watchBattery: Double?
    var phoneBattery: Double?
    var watchCharging: Bool?
    var phoneReachable: Bool

    static let empty = AppData(latitude: nil, longitude: nil, altitude: nil, accuracy: nil, city: nil, country: nil, temperature: nil, feelsLike: nil, condition: nil, humidity: nil, windSpeed: nil, windDirection: nil, rainChance: nil, updatedAt: nil, watchBattery: nil, phoneBattery: nil, watchCharging: nil, phoneReachable: false)
}
