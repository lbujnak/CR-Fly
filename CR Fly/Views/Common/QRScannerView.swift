import AVKit
import SwiftUI

/// `QRScannerView` is a SwiftUI view that encapsulates the `CameraPreview` specifically configured for scanning QR codes. It includes visual enhancements and controls to facilitate effective scanning.
public struct QRScannerView: View {
    /// An instance of `QRCodeScannerController` which manages the camera setup and QR scanning logic.
    private let qrScanner: QRCodeScannerController
    
    /** Initializes a `QRScannerView`.
    - Parameter qrScanner: An instance of `QRCodeScannerController` which manages the camera setup and QR scanning logic.
    */
    public init(qrScanner: QRCodeScannerController) {
        self.qrScanner = qrScanner
    }
    
    /// Constructs the UI for QR code scanning, integrating `CameraPreview` and additional visual cues to assist users during scanning.
    public var body: some View {
        GeometryReader {
            let size = $0.size
            
            ZStack {
                QRCameraPreview(qrScanner: self.qrScanner, size: CGSize(width: size.height, height: size.height))
                    .onDisappear(perform: self.qrScanner.stopScanning)
                    .onAppear {
                        self.qrScanner.startScanning()
                        self.qrScanner.updateOrientation()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                        self.qrScanner.updateOrientation()
                    }
                
                ForEach(0 ... 4, id: \.self) { index in
                    let rotation = Double(index) * 90
                    RoundedRectangle(cornerRadius: 2, style: .circular).trim(from: 0.61, to: 0.64).stroke(Color.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)).rotationEffect(.init(degrees: rotation), anchor: .center)
                }
            }.frame(width: size.height, height: size.height)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }.padding(.horizontal, 45)
    }
}
