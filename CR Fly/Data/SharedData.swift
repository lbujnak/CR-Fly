import Foundation

/// `SharedData` is an observable data model class that centralizes common data used across different components of the application. This class manages shared states such as current location, QR scanner status, and the result of QR scans, ensuring that these states are synchronized across the UI wherever they are displayed or utilized.
public class SharedData: ObservableObject {
    /// A string that stores the formatted address of the current location. This can be used to display location information consistently across various views in the application.
    @Published public var currentLocationAddress: String = ""
    
    /// A boolean that indicates whether the QR scanner is actively scanning. This helps in managing scanner operations and UI elements associated with scanning actions.
    @Published public var qrScannerIsRunning = false
    
    /// A string that holds the result of the latest QR scan. This is useful for processing and responding to QR code data within the application.
    @Published public var qrScannerScannedCode = ""
}
