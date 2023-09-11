import SwiftUI
import AVKit

struct ScannerView: View {
    @State private var isScanning: Bool = false

    @State private var session: AVCaptureSession = .init()
    @State private var qrOutput: AVCaptureMetadataOutput = .init()
    @State private var cameraPermission: Permission = .idle
    
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    @Environment(\.openURL) private var openURL
    @StateObject private var qrDelegate = QRScannerDelegate()
    @StateObject private var appData = ApplicationData.shared
    
    var body: some View {
        VStack(spacing: 8){
            // MARK: Header bar + info
            HStack{
                Button("←"){
                    ViewController.shared.changeView(type: .mainView)
                }.font(.largeTitle)
                
                Spacer()
                
                Text("Place the QR code inside the area").font(.title3).foregroundColor(.black.opacity(0.8)).padding(.top,20).padding(.top,-20)
                
                Spacer()
                Button{
                    if(!session.isRunning && cameraPermission == .approved) {
                        activateScanner()
                    }
                } label: {
                    Image(systemName: "qrcode.viewfinder").font(.largeTitle).foregroundColor(.gray)
                }.disabled(session.isRunning || cameraPermission != .approved)
            }.ignoresSafeArea()
            
            Text("Scanning will start automatically or with pressing button").font(.callout).foregroundColor(.gray).multilineTextAlignment(.center).padding(.top,-10)
            
            Spacer(minLength: 15)
            
            // MARK: QRCodeScanner 
            GeometryReader{
                let size = $0.size
                
                ZStack{
                    DeviceCameraView(frameSize: CGSize(width: size.height, height: size.height), session: $session).rotationEffect(.init(degrees: appData.orientation == 4 ? 90 : -90))
                    
                    ForEach(0...4, id: \.self){ index in
                        let rotation = Double(index) * 90
                        RoundedRectangle(cornerRadius: 2, style: .circular).trim(from: 0.61,to: 0.64).stroke(Color.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)).rotationEffect(.init(degrees: rotation))
                    }
                    
                }.frame(width: size.height, height: size.height)
                .overlay(alignment: .top, content: {
                    Rectangle().fill(Color.blue).frame(height: 2.5).shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: isScanning ? 15 : -15).offset(y: isScanning ? size.height : 0)
                }).frame(maxWidth: .infinity, maxHeight: .infinity)
            }.padding(.horizontal, 45)
        }
        .padding(15).background(Color.white)
        .onAppear(perform: checkCameraPermission)
        .onDisappear(perform: deActivateScanner)
        .onChange(of: qrDelegate.scannedCode){ newVal in
            if let code = newVal {
                deActivateScanner()
                
                if(code.starts(with: "https://rcnode.capturingreality.com/autoredirect?")){
                    var dict = [String:String]()
                    let components = URLComponents(url: URL(string: code)!, resolvingAgainstBaseURL: false)!
                    if let queryItems = components.queryItems {
                        for item in queryItems {
                            dict[item.name] = item.value!
                        }
                    }
                    
                    let addresses = dict["allAddresses"]!.replacingOccurrences(of: "[\\[\\]\" ]", with: "", options: .regularExpression).components(separatedBy: ",")
                    
                    ApplicationData.shared.rcAuthTkn = dict["authToken"]!
                    ApplicationData.shared.rcNodeIP = addresses
                    
                    //Command connect to RC
                    
                    ViewController.shared.changeView(type: .mainView)
                } else {
                    presentError("Found Invalid QR Code for RC Node")
                }
            }
        }
        .alert(errorMessage, isPresented: $showError){
            if cameraPermission == .denied {
                Button("Settings"){
                    let settingsString = UIApplication.openSettingsURLString
                    if let settingsURL = URL(string: settingsString){ openURL(settingsURL) }
                }
                Button("Cancel",role: .cancel){ }
            }
        }
    }
    
    func activateScanner() {
        DispatchQueue.global(qos: .background).async {
            session.startRunning()
        }
        
        withAnimation(.easeInOut(duration: 0.85).delay(0.1).repeatForever(autoreverses: true)) {
            isScanning = true
        }
    }
    
    func deActivateScanner(){
        session.stopRunning()
        qrDelegate.scannedCode = nil
        
        withAnimation(.easeInOut(duration: 0.85)) {
            isScanning = false
        }
    }
    
    func checkCameraPermission() {
        if(!session.inputs.isEmpty){
            qrOutput.setMetadataObjectsDelegate(qrDelegate, queue: .main)
            activateScanner()
            return
        }
        
        Task{
            switch AVCaptureDevice.authorizationStatus(for: .video){
                case .authorized:
                    cameraPermission = .approved
                    setupCamera()
                    return
                case .notDetermined:
                    if await AVCaptureDevice.requestAccess(for: .video){
                        cameraPermission = .approved
                        setupCamera()
                        return
                    } else {
                        cameraPermission = .denied
                        presentError("Please Provide Access to Camera for Qr Scanner")
                        return
                    }
                case .denied, .restricted:
                    cameraPermission = .denied
                    presentError("Please Provide Access to Camera for Qr Scanner")
                    return
                default: return
            }
        }
    }
    
    func setupCamera(){
        do {
            guard let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInUltraWideCamera,.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first else {
                presentError("Error While Preparing Qr Scanner: Unknown Device Error")
                return
            }
            
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input), session.canAddOutput(qrOutput) else {
                presentError("Error While Preparing Qr Scanner: Unknown I/O Error")
                return
            }
            
            session.beginConfiguration()
            session.addInput(input)
            session.addOutput(qrOutput)
            
            qrOutput.metadataObjectTypes = [.qr]
            qrOutput.setMetadataObjectsDelegate(qrDelegate, queue: .main)
            session.commitConfiguration()
            activateScanner()
        } catch { presentError(error.localizedDescription) }
    }
    
    func presentError(_ message: String){
        errorMessage = message
        showError.toggle()
    }
}

struct ScannerView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerView()
    }
}
