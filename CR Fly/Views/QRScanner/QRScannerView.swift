
import SwiftUI
import AVKit

struct CameraPreview: UIViewRepresentable {
    let qrScanner: QRCodeScanner
    let size: CGSize

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: CGRect(origin: .zero, size: size))
        qrScanner.preview.frame = view.bounds
        view.layer.addSublayer(qrScanner.preview)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}


struct QRScannerView: View {
    let qrScanner: QRCodeScanner

    var body: some View {
        GeometryReader{
            let size = $0.size
            
            ZStack{
                CameraPreview(qrScanner: qrScanner, size: CGSize(width: size.height, height: size.height))
                    .onAppear(perform: qrScanner.startScanning)
                    .onDisappear(perform: qrScanner.stopScanning)
                    .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                        qrScanner.updateOrientation()
                    }
                    /*.alert(errorMessage, isPresented: $showError){
                        if cameraPermission == .denied {
                            Button("Settings"){
                                let settingsString = UIApplication.openSettingsURLString
                                if let settingsURL = URL(string: settingsString){ openURL(settingsURL) }
                            }
                            Button("Cancel",role: .cancel){ }
                        }
                    }*/
                
                /*//MARK: PRESENT ERROR
                func presentError(_ message: String){
                    errorMessage = message
                    showError.toggle()
                }*/
                
                ForEach(0...4, id: \.self){ index in
                    let rotation = Double(index) * 90
                    RoundedRectangle(cornerRadius: 2, style: .circular).trim(from: 0.61,to: 0.64).stroke(Color.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)).rotationEffect(.init(degrees: rotation), anchor: .center)
                }
            }.frame(width: size.height, height: size.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }.padding(.horizontal, 45)
    }
}
