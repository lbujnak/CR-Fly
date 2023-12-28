import SwiftUI
import AVKit

class QRCodeScannerController: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    
    @Published var isRunning = false
    @Published var scannedCode = ""
    
    var session = AVCaptureSession()
    var preview = AVCaptureVideoPreviewLayer()
    
    @Environment(\.openURL) private var openURL
    private var viewController = CRFly.shared.viewController
    
    override init() {
        super.init()
        self.validateAccesAndConfigure()
    }
    
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
    
    private func validateAccesAndConfigure() {
        self.session.beginConfiguration()
        self.preview.session = session
        self.preview.frame = UIScreen.main.bounds
        self.preview.videoGravity = .resizeAspectFill
        self.session.commitConfiguration()
        
        self.updateOrientation()
        
        //Check permissions
        if(session.inputs.isEmpty){
            Task {
                let hasAccess = await self.checkAndRequestCameraAccess()
                if !hasAccess {
                    DispatchQueue.main.async {
                        self.viewController.showAlert(title: "Permissions Error",
                            msg: Text("To use the QR Code Scanner, please grant camera access"),
                            buttons: [
                                (label: "Settings", action: {
                                    let settingsString = UIApplication.openSettingsURLString
                                    if let settingsURL = URL(string: settingsString){ self.openURL(settingsURL) }
                                }),
                                (label: "Cancel", action: { })
                            ]
                        )
                    }
                } else {
                    self.setupScanningSession()
                }
            }
        } else {
            self.setupScanningSession()
        }
    }

    private func setupScanningSession() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video), let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice)
        else {
            self.viewController.showSimpleAlert(title: "Unknown Device Error", msg: Text("Error while preparing QRCode Scanner"))
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        guard session.canAddInput(videoInput), session.canAddOutput(metadataOutput) else {
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
    
    func updateOrientation() {
        if(UIDevice.current.orientation == .landscapeRight){
            self.preview.setAffineTransform(CGAffineTransform(rotationAngle: .pi/2))
        } else if(UIDevice.current.orientation == .landscapeLeft){
            self.preview.setAffineTransform(CGAffineTransform(rotationAngle: -(.pi/2)))
        }
    }

    func startScanning() {
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
        self.isRunning = true
        self.scannedCode = ""
    }

    func stopScanning() {
        self.session.stopRunning()
        self.isRunning = false
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metaObject = metadataObjects.first {
            guard let readableObject = metaObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let code = readableObject.stringValue else { return }
            
            self.scannedCode = code
            self.stopScanning()
        }
    }
}
