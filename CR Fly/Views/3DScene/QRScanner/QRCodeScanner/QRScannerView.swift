
import SwiftUI
import AVKit

struct CameraPreview: UIViewRepresentable {
    let qrScanner: QRCodeScannerController
    let size: CGSize

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: CGRect(origin: .zero, size: self.size))
        self.qrScanner.preview.frame = view.bounds
        view.layer.addSublayer(self.qrScanner.preview)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}


struct QRScannerView: View {
    let qrScanner: QRCodeScannerController

    var body: some View {
        GeometryReader{
            let size = $0.size
            
            ZStack{
                CameraPreview(qrScanner: self.qrScanner, size: CGSize(width: size.height, height: size.height))
                    .onAppear(perform: self.qrScanner.startScanning)
                    .onDisappear(perform: self.qrScanner.stopScanning)
                    .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                        self.qrScanner.updateOrientation()
                    }
                
                ForEach(0...4, id: \.self){ index in
                    let rotation = Double(index) * 90
                    RoundedRectangle(cornerRadius: 2, style: .circular).trim(from: 0.61,to: 0.64).stroke(Color.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)).rotationEffect(.init(degrees: rotation), anchor: .center)
                }
            }.frame(width: size.height, height: size.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }.padding(.horizontal, 45)
    }
}

#Preview {
    QRScannerView(qrScanner: QRCodeScannerController())
}
