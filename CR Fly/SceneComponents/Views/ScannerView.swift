import AVKit
import SwiftUI

/**
 `ScannerView` is a SwiftUI view that incorporates QR code scanning and manual input functionalities to facilitate pairing with external services like RealityCapture. It provides an interface for scanning QR codes or manually entering connection credentials.
 
 - The view is primarily used to establish a connection to RealityCapture by scanning a QR code or entering details manually.
 - Upon successful scanning or input, the app attempts to validate and connect to the provided server, updating the user interface based on the connection status.
 
 This view interacts with the system's camera to scan QR codes and uses state management to handle user inputs and system responses dynamically.
 */
public struct ScannerView: AppearableView {
    /// Reference to the `ViewController` responsible for managing navigation, presentation of different views within the application and displaying errors.
    private let viewController: ViewController
    
    /// Reference to an instance of `SceneController` that manages broader scene-related operations.
    private let sceneController: RCNodeController
    
    /// An instance of `QRCodeScannerController` used to handle QR code scanning functionalities.
    private let qrScanner: QRCodeScannerController
    
    /// Reference to observable object `SharedData` which contains common data used across different components of the application.
    @ObservedObject private var sharedData: SharedData
    
    /// An optional string that displays the current verification or connection status. It helps in providing feedback about the ongoing process.
    @State private var verifyStatus: String? = nil
    
    /// A Boolean that toggles between QR code scanning and manual input mode. This allows users to manually enter connection details if the QR scan is not possible.
    @State private var manualInput: Bool = false
    
    ///  A string that holds the manually entered IP address.
    @State private var manualIPAddr: String = ""
    
    /// A string for manually entering the authentication token.
    @State private var manualAuthTok: String = ""
    
    /// Called when the object becomes visible within the user interface.
    public func appear() {
        self.prepareScanner()
    }
    
    /// Called when the object is no longer visible within the user interface.
    public func disappear() {
        self.qrScanner.stopScanning()
    }
    
    /// Initializes the `ScannerView`,
    public init(viewController: ViewController, sceneController: SceneController, sharedData: SharedData) {
        self.viewController = viewController
        self.sceneController = sceneController as! RCNodeController
        self.sharedData = sharedData
        self.qrScanner = QRCodeScannerController(viewController: viewController, sharedData: sharedData)
    }
    
    /// The `body` property defines the user interface of the `ScannerView`. It constructs the view hierarchy and manages the dynamic aspects of the interface based on the application state and user interactions. This view is responsible for displaying both the QR code scanner and the manual input form, along with relevant status messages and interactive elements.
    public var body: some View {
        ZStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 8) {
                        
                        // MARK: Header bar + info
                        HStack {
                            Button("←") {
                                if !self.manualInput { self.viewController.displayPreviousView() }
                                else { self.manualInput = false }
                            }.font(.largeTitle).foregroundColor(.primary)
                            
                            Spacer()
                            Text(!self.manualInput ? "Scan QR Code to pair with RealityCapture" : "Please enter IP Address and Auth Token from RealityCapture").font(.title3)
                                .foregroundColor(.primary.opacity(0.8)).padding(.top, 20).padding(.top, -20)
                            Spacer()
                        }.ignoresSafeArea()
                        
                        HStack {
                            Text(!self.manualInput ? "Alternatively, you can enter it manually by " : "Alternatively, you can confirm pre-filled fields to reestablish the previous connection.").foregroundColor(.secondary)
                            
                            if !self.manualInput {
                                Button("clicking here") {
                                    self.manualInput = true
                                    self.qrScanner.stopScanning()
                                }.padding(.leading, -6).bold()
                                
                                Text(".").padding(.leading, -6).foregroundColor(.secondary)
                            }
                        }.font(.callout).multilineTextAlignment(.center).padding(.top, -10)
                        
                        Spacer(minLength: 15)
                        
                        if self.manualInput {
                            
                            // MARK: Manual-Input View
                            self.manualInputContent()
                            Spacer()
                        } else {
                            
                            // MARK: QRCodeScanner
                            QRScannerView(qrScanner: self.qrScanner).onChange(of: self.sharedData.qrScannerScannedCode) {
                                if self.sharedData.qrScannerScannedCode == "" { return }
                                self.validateQRAndConnect()
                            }
                        }
                    }.padding(15).frame(width: geometry.size.width, height: geometry.size.height).multilineTextAlignment(.center)
                }.scrollDisabled(!self.manualInput).scrollDismissesKeyboard(.immediately)
            }
            
            // MARK: Loading bar
            if self.verifyStatus != nil {
                Color.secondary.opacity(0.5).ignoresSafeArea()
                VStack {
                    HStack(spacing: 20) {
                        ProgressView().tint(.primary)
                        Text(self.verifyStatus!)
                    }.padding()
                }.background(Color(UIColor.systemBackground)).cornerRadius(10).foregroundColor(.primary)
                    .frame(width: 300, height: 70)
            }
            
        }.onChange(of: self.manualInput) { _, new in
            if !new { self.prepareScanner() }
        }
    }
    
    /// Prepares and starts the QR code scanner.
    private func prepareScanner() {
        self.verifyStatus = nil
        self.qrScanner.startScanning()
    }
    
    /// Returns a view for manually entering the IP address and authentication token.
    private func manualInputContent() -> some View {
        
        // MARK: Inputs and ConnectBtn
        Group {
            HStack {
                Text("IP Address:")
                Spacer()
                TextField("IP Address", text: self.$manualIPAddr)
                    .padding([.top, .bottom], 5).padding([.leading, .trailing], 15)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10).frame(width: 250).multilineTextAlignment(.leading)
            }.frame(minWidth: 360, maxWidth: 360)
            HStack {
                Text("Auth Token:")
                Spacer()
                TextField("Auth Token", text: self.$manualAuthTok)
                    .padding([.top, .bottom], 5).padding([.leading, .trailing], 15)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10).frame(width: 250).multilineTextAlignment(.leading)
            }.frame(minWidth: 360, maxWidth: 360)
            HStack {
                Button {
                    self.connectSubmit(addresses: [self.manualIPAddr], authToken: self.manualAuthTok)
                } label: {
                    Text("Connect").frame(minWidth: 360, maxWidth: 360, minHeight: 40, maxHeight: 40).foregroundColor(.white)
                }.background(Color.blue).cornerRadius(8)
            }.padding([.top], 15)
        }
    }
    
    /// Validates the scanned QR code and attempts to establish a connection.
    private func validateQRAndConnect() {
        self.verifyStatus = "Validating QRCode..."
        
        if self.sharedData.qrScannerScannedCode.starts(with: "http://rcnode.capturingreality.com/autoredirect?") {
            var dict = [String: String]()
            let components = URLComponents(url: URL(string: sharedData.qrScannerScannedCode)!, resolvingAgainstBaseURL: false)!
            
            if let queryItems = components.queryItems {
                for item in queryItems {
                    dict[item.name] = item.value!
                }
            }
            
            guard let addrs = dict["allAddresses"], let token = dict["authToken"] else {
                self.invalidQRCode(title: "QRCode Scanner Error", msg: "Found invalid QRCode for RealityCapture.")
                return
            }
            
            let addList = addrs.replacingOccurrences(of: "[\\[\\]\" ]", with: "", options: .regularExpression).components(separatedBy: ",")
            self.connectSubmit(addresses: addList, authToken: token)
        } else {
            self.invalidQRCode(title: "QRCode Scanner Error", msg: "Found invalid QRCode for RealityCapture.")
        }
    }
    
    /// Attempts to connect using manually entered details.
    private func connectSubmit(addresses: [String], authToken: String) {
        Task {
            self.verifyStatus = "Connecting to RCNode..."
            
            let result = await sceneController.startConnectionTo(addresses: addresses, authToken: authToken)
            if result {
                DispatchQueue.main.async {
                    self.viewController.displayPreviousView()
                    self.viewController.showSimpleAlert(title: "RCNode Connection Success", msg: Text("The connection to RCNode has been successfully established. Please select a project through the 'i-button' to load its data."))
                }
            } else {
                self.invalidQRCode(title: "RCNode Connection Error", msg: "Failed to establish a connection to the RCNode due to an invalid IP address or authentication token.", onCancelStart: !self.manualInput)
            }
            self.verifyStatus = nil
        }
    }
    
    /// Displays an alert for an invalid QR code or failed connection attempt.
    private func invalidQRCode(title: String, msg: String, onCancelStart: Bool = true) {
        self.verifyStatus = nil
        self.viewController.showAlert(title: title,
                                      msg: Text(msg),
                                      buttons: [(label: "Cancel", action: { if onCancelStart { self.qrScanner.startScanning() }} )]
        )
    }
}
