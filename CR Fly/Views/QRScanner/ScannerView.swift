import SwiftUI
import AVKit

struct ScannerView: View {
    
    @State var verifyingQRCode: Bool = false
    @State var verifyStatus: String = ""
    @State var manualInput: Bool = false
    
    @Environment(\.colorScheme) var colorScheme
    @StateObject var qrScanner = QRCodeScanner()
    
    var body: some View {
        @State var isScanning = self.qrScanner.isRunning
        ZStack{
            VStack(spacing: 8){
                // MARK: Header bar + info
                HStack{
                    Button("←"){
                        CRFly.shared.viewController.changeView(type: .mainView)
                    }.font(.largeTitle).foregroundColor(Color.blue)
                    
                    Spacer()
                    Text("Scan QR Code to pair with RealityCapture").font(.title3).foregroundColor(.primary.opacity(0.8)).padding(.top,20).padding(.top,-20)
                    Spacer()
                
                    Button{
                        if(!isScanning) { qrScanner.startScanning() }
                    } label: {
                        Image(systemName: "qrcode.viewfinder").font(.largeTitle).foregroundColor(isScanning ? .secondary : .blue)
                    }.disabled(isScanning)
                }.ignoresSafeArea()
                
                HStack{
                    Text("Alternatively, you can enter it manually by ").foregroundColor(.secondary)
                    Button("clicking here"){
                        self.manualInput = true
                        qrScanner.stopScanning()
                    }.padding(.leading, -6).bold()
                    
                    Text(".").padding(.leading, -6).foregroundColor(.secondary)
                }.font(.callout).multilineTextAlignment(.center).padding(.top,-10)
                
                Spacer(minLength: 15)
                    
                // MARK: QRCodeScanner
                QRScannerView(qrScanner: self.qrScanner).onChange(of: self.qrScanner.scannedCode){
                    if(self.qrScanner.scannedCode == "") { return }
                    self.validateAndConnect()
                }
            }.padding(15)
            
            //Loading bar
            if(self.verifyingQRCode){
                Color.secondary.opacity(0.5).ignoresSafeArea()
                VStack{
                    Spacer()
                    HStack {
                        Spacer()
                        ProgressView().tint(.primary)
                        Spacer()
                        Text(self.verifyStatus)
                        Spacer()
                    }
                    Spacer()
                }.background(colorScheme == .dark ? .black : .white).cornerRadius(10).foregroundColor(.primary).frame(width: 300, height: 70)
            }
        }.onAppear(){
            self.verifyStatus = ""
            self.verifyingQRCode = false
        }.sheet(isPresented: self.$manualInput) {
            ManualInputView(manualInput: self.$manualInput, verifyStatus: self.$verifyStatus, verifyingQRCode: self.$verifyingQRCode)
        }
    }
    
    private func invalidQRCode() {
        CRFly.shared.viewController.showSimpleAlert(title: "QRCode Scanner Error", msg: Text("Found invalid QRCode for RealityCapture"))
        self.verifyingQRCode = false
        self.verifyStatus = ""
    }

    private func validateAndConnect(){
        print(self.qrScanner.scannedCode)
        
        self.verifyStatus = "Validating QRCode..."
        self.verifyingQRCode = true
        
        if(self.qrScanner.scannedCode.starts(with: "http://rcnode.capturingreality.com/autoredirect?")){
            var dict = [String:String]()
            let components = URLComponents(url: URL(string: self.qrScanner.scannedCode)!, resolvingAgainstBaseURL: false)!
            
            if let queryItems = components.queryItems {
                for item in queryItems {
                    dict[item.name] = item.value!
                }
            }
            
            guard let addrs = dict["allAddresses"], let token = dict["authToken"] else {
                self.invalidQRCode()
                return
            }
                
            let addList = addrs.replacingOccurrences(of: "[\\[\\]\" ]", with: "", options: .regularExpression).components(separatedBy: ",")
            
            self.verifyStatus = "Connecting to RealityCapture..."
                
            //CRFly.shared.appData.rcAuthTkn = dict["authToken"]!
            //CRFly.shared.appData.rcNodeIP = addresses
                
            //Command connect to RC
            
        } else { self.invalidQRCode() }
    }
}

struct ScannerView_Previews: PreviewProvider {
    static let qrScanner = QRCodeScanner()
    static var previews: some View {
        ScannerView(qrScanner: qrScanner)
    }
}
