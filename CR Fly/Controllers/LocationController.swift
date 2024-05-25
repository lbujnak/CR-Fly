
import CoreLocation

/// `LocationController` manages real-time location updates via CLLocationManager.
public class LocationController: NSObject, CLLocationManagerDelegate {
    /// The CLLocationManager object configured to manage and deliver location events to the application.
    private let locationManager: CLLocationManager
    
    /// Reference to observable object `SharedData` which contains common data used across different components of the application.
    private let sharedData: SharedData
    
    /// Initializes a new instance of `LocationController`.
    public init(sharedData: SharedData) {
        self.locationManager = CLLocationManager()
        self.sharedData = sharedData
        super.init()
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        self.locationManager.distanceFilter = 50
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    /// Processes location updates. nherited from CLLocationManagerDelegate.locationManager(_:didUpdateLocations:).
    public func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, _ in
                if let placemark = placemarks?.first {
                    let address = "\(placemark.name ?? ""), \(placemark.locality ?? ""), \(placemark.country ?? "")"
                    self.sharedData.currentLocationAddress = address
                }
            }
        }
    }
    
    /// Handles errors encountered while updating locations. Inherited from CLLocationManagerDelegate.locationManager(_:didFailWithError:).
    public func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        print("Chyba pri získavaní polohy: \(error)")
    }
}
