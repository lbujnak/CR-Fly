import AVKit
import SwiftUI

/// `QRCodeScannerController` manages the QR code scanning functionality using AVCaptureSession.
public class QRCodeScannerController: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    /// Reference to the `ViewController` responsible for managing navigation, presentation of different views within the application and displaying errors.
    private let viewController: ViewController
    
    /// Reference to observable object `SharedData` which contains common data used across different components of the application.
    private let sharedData: SharedData
    
    /// AVCaptureSession instance for managing the camera and capturing frames.
    private let session = AVCaptureSession()
    
    /// AVCaptureVideoPreviewLayer for displaying the camera feed.
    private let preview = AVCaptureVideoPreviewLayer()
    
    @Environment(\.openURL) private var openURL
    
    /// Initializes a new instance of `QRCodeScannerController`, configuring the camera session and validating access.
    public init(viewController: ViewController, sharedData: SharedData) {
        self.viewController = viewController
        self.sharedData = sharedData
        super.init()
        
        self.validateAccesAndConfigure()
    }
    
    /// Retrieves the preview layer for displaying the camera feed.
    public func getPreview() -> AVCaptureVideoPreviewLayer {
        self.preview
    }
    
    /// Updates the orientation of the camera preview based on the device orientation.
    public func updateOrientation() {
        if let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation {
            if orientation.isLandscape {
                if orientation == .landscapeRight {
                    self.preview.setAffineTransform(CGAffineTransform(rotationAngle: -(.pi / 2)))
                } else if orientation == .landscapeLeft {
                    self.preview.setAffineTransform(CGAffineTransform(rotationAngle: .pi / 2))
                }
            }
        }
    }
    
    /// Starts the QR code scanning process by initiating the AVCaptureSession.
    public func startScanning() {
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
        self.sharedData.qrScannerIsRunning = true
        self.sharedData.qrScannerScannedCode = ""
    }
    
    /// Stops the QR code scanning process by stopping the AVCaptureSession.
    public func stopScanning() {
        self.session.stopRunning()
        self.sharedData.qrScannerIsRunning = true
    }
    
    /// Validates access to the camera and configures the AVCaptureSession for QR code scanning.
    private func validateAccesAndConfigure() {
        self.session.beginConfiguration()
        self.preview.session = self.session
        self.preview.frame = UIScreen.main.bounds
        self.preview.videoGravity = .resizeAspectFill
        self.session.commitConfiguration()
        
        self.updateOrientation()
        
        // Check permissions
        if self.session.inputs.isEmpty {
            Task {
                let hasAccess = await self.checkAndRequestCameraAccess()
                if !hasAccess {
                    DispatchQueue.main.async {
                        self.viewController.showAlert(
                            title: "Permissions Error",
                            msg: Text("To use the QR Code Scanner, please grant camera access"),
                            buttons: [
                                (label: "Settings", action: {
                                    let settingsString = UIApplication.openSettingsURLString
                                    if let settingsURL = URL(string: settingsString) { self.openURL(settingsURL) }
                                }), (label: "Cancel", action: {})
                            ]
                        )
                    }
                } else { self.setupScanningSession() }
            }
        } else { self.setupScanningSession() }
    }
    
    /// Checks camera permissions and requests access if needed.
    private func checkAndRequestCameraAccess() async -> Bool {
        let camAccess = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch camAccess {
        case .denied, .restricted:
            return false
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return true
        }
    }
    
    /// Sets up the AVCaptureSession for scanning QR codes.
    private func setupScanningSession() {
        DispatchQueue.main.async {
            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video), let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
                self.viewController.showSimpleAlert(title: "Unknown Device Error", msg: Text("Error while preparing QRCode Scanner"))
                return
            }
            
            let metadataOutput = AVCaptureMetadataOutput()
            guard self.session.canAddInput(videoInput), self.session.canAddOutput(metadataOutput) else {
                self.viewController.showSimpleAlert(title: "Unknown I/O Error", msg: Text("Error while preparing QRCode Scanner"))
                return
            }
            
            self.session.beginConfiguration()
            self.session.addInput(videoInput)
            self.session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
            self.session.commitConfiguration()
        }
    }
    
    /// Delegate method called when metadata objects are captured during scanning.
    public func metadataOutput(_: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from _: AVCaptureConnection) {
        if let metaObject = metadataObjects.first {
            guard let readableObject = metaObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let code = readableObject.stringValue else { return }
            
            DispatchQueue.main.async {
                self.sharedData.qrScannerScannedCode = code
                self.stopScanning()
            }
        }
    }
}
