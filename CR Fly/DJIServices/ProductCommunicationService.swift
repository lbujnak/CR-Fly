import DJISDK
import SwiftUI

class ProductCommunicationService: NSObject, ObservableObject {
    
    @ObservedObject static var shared = ProductCommunicationService()
    
    @Published var sdkRegistered = false
    @Published var connected = false
    @Published var enableBridgeMode = false //false
    @Published var bridgeAppIP = "192.168.10.42"
    
    var libController : LibraryCommunicationService = LibraryCommunicationService()
    
    func registerWithSDK() {
        let appKey = Bundle.main.object(forInfoDictionaryKey: SDK_APP_KEY_INFO_PLIST_KEY) as? String
        
        guard appKey != nil && appKey!.isEmpty == false else {
            GlobalAlertHelper.shared.createAlert(title: "AppKey error", msg: "Please enter your app key in the info.plist")
            return
        }
        DJISDKManager.registerApp(with: self)
        
    }
    
    func connectToProduct(){
        DJISDKManager.stopConnectionToProduct()
        if (self.enableBridgeMode) {
            DJISDKManager.enableBridgeMode(withBridgeAppIP: self.bridgeAppIP)
            print("Bridge connection to " + self.bridgeAppIP + " has been started.")
        } else {
            if (DJISDKManager.startConnectionToProduct()) {
                print("Connection has been started.")
            } else {
                GlobalAlertHelper.shared.createAlert(title: "Connection error", msg: "There was a problem starting the connection.")
            }
        }
    }
    
    func disconnect(){
        DJISDKManager.stopConnectionToProduct()
    }
    
    func stopBridgeMode(){
        self.connected = false
        self.enableBridgeMode = false
        DJISDKManager.disableBridgeMode()
        print("Bridge connection to " + self.bridgeAppIP + " has been disabled.")
    }
}

extension ProductCommunicationService : DJISDKManagerDelegate {
    
    func didUpdateDatabaseDownloadProgress(_ progress: Progress) {
        print("SDK downloading db file \(progress.completedUnitCount / progress.totalUnitCount)")
    }
    
    func appRegisteredWithError(_ error: Error?) {
        if (error != nil) {
            GlobalAlertHelper.shared.createAlert(title: "SDK Registered with error", msg: error!.localizedDescription)
            return
        }
        
        self.sdkRegistered = true
        self.connectToProduct()
    }
    
    func productConnected(_ product: DJIBaseProduct?) {
        print("Entered productConnected")
        guard let _ = product else {
            print("Product connected but was nil")
            GlobalAlertHelper.shared.createAlert(title: "Connection error", msg: "There was a problem connectiong to device.")
            return
        }
        self.connected = true
    }
    
    func productDisconnected() {
        print("Entered productDisconnected")
        self.connected = false
        self.libController.mediaFetched = false
        self.libController.mediaLibPicked = nil
        self.libController.mediaSections = []
        self.libController.mediaList = []
        self.libController.mediaPreviewReady = false
        self.libController.mediaPreviewVideoCTime = 0
        self.libController.mediaPreviewVideoPlaying = false
        
        if(ViewHelper.shared.libMode) { ViewHelper.shared.libMode = false }
        if(ViewHelper.shared.fpvMode) { ViewHelper.shared.fpvMode = false }
    }
    
    func componentConnected(withKey key: String?, andIndex index: Int) {
        print("Entered componentConnected")
        if(!self.connected && DJISDKManager.product() != nil && DJISDKManager.product()!.model != "Only RemoteController"){
            self.productConnected(DJISDKManager.product())
        }
    }
    
    func componentDisconnected(withKey key: String?, andIndex index: Int) {
        print("Entered componentDisonnected")
        if(self.connected && (DJISDKManager.product() == nil || DJISDKManager.product()!.model == "Only RemoteController")){
            self.productDisconnected()
        }
    }
}
