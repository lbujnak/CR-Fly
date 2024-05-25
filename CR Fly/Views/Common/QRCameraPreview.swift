import SwiftUI

/// `CameraPreview` provides a SwiftUI view representation of a live camera feed using `UIViewRepresentable` to integrate UIKit's `UIView` within SwiftUI. It serves as a container for displaying camera output, specifically tailored for QR code scanning functionalities provided by a `QRCodeScannerController`.
public struct QRCameraPreview: UIViewRepresentable {
    /// An instance of `QRCodeScannerController` which manages the camera setup and QR scanning logic.
    private let qrScanner: QRCodeScannerController
    
    /// The desired size of the camera preview within the SwiftUI view hierarchy.
    private let size: CGSize
    
    /** Initializes the `CameraPreview`.
    - Parameter qrScanner: An instance of `QRCodeScannerController` which manages the camera setup and QR scanning logic.
    - Parameter size: The desired size of the camera preview within the SwiftUI view hierarchy.
    */
    public init(qrScanner: QRCodeScannerController, size: CGSize) {
        self.qrScanner = qrScanner
        self.size = size
    }
    
    /// SwiftUI lifecycle methods for managing the UIView within SwiftUI's view hierarchy. Constructs and configures the underlying `UIView` that hosts the camera feed. Sets up the initial frame and camera layer.
    public func makeUIView(context _: Context) -> UIView {
        let view = UIView(frame: CGRect(origin: .zero, size: size))
        self.qrScanner.getPreview().frame = view.bounds
        view.layer.addSublayer(self.qrScanner.getPreview())
        
        return view
    }
    
    /// SwiftUI lifecycle methods for managing the UIView within SwiftUI's view hierarchy. Updates the existing UIView when SwiftUI re-renders or updates the view. Currently a no-operation as the camera view does not need to update with new data.
    public func updateUIView(_: UIView, context _: Context) {}
}
