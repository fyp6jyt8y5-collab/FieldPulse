import CoreLocation
import Combine
import Foundation

@MainActor
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var location: CLLocation?
    @Published private(set) var placemark: CLPlacemark?
    @Published private(set) var authorization: CLAuthorizationStatus
    @Published private(set) var heading: CLHeading?
    @Published private(set) var errorMessage: String?
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        authorization = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 25
        manager.headingFilter = 5
    }

    func requestPermissionAndStart() {
        guard CLLocationManager.locationServicesEnabled() else { errorMessage = "Location services are disabled."; return }
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() { manager.startUpdatingHeading() }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization = manager.authorizationStatus
        if authorization == .authorizedWhenInUse || authorization == .authorizedAlways { manager.startUpdatingLocation() }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        location = latest
        Task {
            do { placemark = try await geocoder.reverseGeocodeLocation(latest).first }
            catch { errorMessage = "Unable to resolve the current city." }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) { heading = newHeading }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { errorMessage = error.localizedDescription }
}
