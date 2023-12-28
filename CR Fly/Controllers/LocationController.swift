import CoreLocation

class MyLocationClass: NSObject, CLLocationManagerDelegate, ObservableObject {
    var locationManager: CLLocationManager
    
    @Published var locationAddress: String = ""

    override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            //let latitude = location.coordinate.latitude
            //let longitude = location.coordinate.longitude

            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                if let placemark = placemarks?.first {
                    let address = "\(placemark.thoroughfare ?? ""), \(placemark.locality ?? ""), \(placemark.country ?? "")"
                    self.locationAddress = address
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Chyba pri získavaní polohy: \(error)")
    }
}
