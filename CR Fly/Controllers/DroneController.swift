import SwiftUI
import DJISDK

class DroneController: NSObject {
    
    private var isExecutingCommand = false
    private var commandQueue: [Command] = []
    
    @State var foundInvalidPlayback: Bool = false
    
    //MARK: Drone Command Queue
    func pushCommand(command: Command) {
        self.commandQueue.append(command)
        if(!self.isExecutingCommand) {
            processNextCommand()
        }
    }
    
    private func processNextCommand() {
        guard !self.isExecutingCommand, !self.commandQueue.isEmpty else { return }

        self.isExecutingCommand = true
        let command = self.commandQueue.removeFirst()
        command.execute {
            self.isExecutingCommand = false
            self.processNextCommand()
        }
    }
    
    //MARK: RegisterSDK and start connection
    func registerWithSDK() {
        let appKey = Bundle.main.object(forInfoDictionaryKey: SDK_APP_KEY_INFO_PLIST_KEY) as? String
        guard appKey != nil && appKey!.isEmpty == false else {
            CRFly.shared.viewController.showSimpleAlert(title: "AppKey error", msg: Text("Please enter your app key in the info.plist"))
            return
        }
        DJISDKManager.registerApp(with: self)
    }
    
    func connectToProduct(){
        if(CRFly.shared.appData.djiDevConn) { return }
        DJISDKManager.stopConnectionToProduct()
        if(!DJISDKManager.startConnectionToProduct()) {
            CRFly.shared.viewController.showSimpleAlert(title: "Drone Connection Error", msg: Text("There was a problem starting the connection."))
        }
    }
    
    private func droneConnected() {
        CRFly.shared.appData.djiDevice = DJISDKManager.product()
        CRFly.shared.appData.djiDevConn = true
        
        let viewType = CRFly.shared.viewController.getViewType()
        if(viewType != .albumMediaPreview){
            CRFly.shared.viewController.addView(type: .albumView, view: AnyView(AlbumView(appData: CRFly.shared.appData, controller: CRFly.shared.droneAlbumController)))
            if(viewType == .albumView){
                CRFly.shared.viewController.changeView(type: .albumView)
            }
        }
    }
    
    private func droneDisconnected() {
        self.commandQueue.removeAll()
        CRFly.shared.appData.djiDevConn = false
        CRFly.shared.appData.djiDevice = nil
        
        CRFly.shared.droneAlbumController.cleanAlbum()
        CRFly.shared.viewController.addView(type: .albumView, view: AnyView(AlbumView(appData: CRFly.shared.appData, controller: CRFly.shared.savedAlbumController)))
        if(CRFly.shared.viewController.getViewType() == .albumView){
            CRFly.shared.viewController.changeView(type: .albumView)
        }
    }
}

//MARK: Delegate DJISDKManager functions
extension DroneController: DJISDKManagerDelegate {
    
    func didUpdateDatabaseDownloadProgress(_ progress: Progress) {
        print("SDK downloading db file \(progress.completedUnitCount / progress.totalUnitCount)")
    }
    
    func appRegisteredWithError(_ error: Error?) {
        if (error != nil) {
            CRFly.shared.viewController.showSimpleAlert(title: "SDK Registered with error", msg: Text(error!.localizedDescription))
            return
        }
        self.connectToProduct()
    }
    
    func componentConnected(withKey key: String?, andIndex index: Int) {
        if(!CRFly.shared.appData.djiDevConn && DJISDKManager.product() != nil && DJISDKManager.product()!.model != "Only RemoteController"){
            self.droneConnected()
        }
    }
    
    func componentDisconnected(withKey key: String?, andIndex index: Int) {
        if(CRFly.shared.appData.djiDevConn && (DJISDKManager.product() == nil ||  DJISDKManager.product()!.model == "Only RemoteController")){
            self.droneDisconnected()
        }
    }
    
}

extension DroneController: DJIMediaManagerDelegate {
    
    func manager(_ manager: DJIMediaManager, didUpdate state: DJIMediaVideoPlaybackState) {
        
        if(!state.playingMedia.valid){
            self.foundInvalidPlayback = true
            CRFly.shared.droneController.pushCommand(command: StopDroneVideoPlayback())
            
        } else if(self.foundInvalidPlayback){
            self.foundInvalidPlayback = false
        }
        
        if(CRFly.shared.appData.droneAlbumPreviewController != nil){
            @ObservedObject var dronePreviewController = CRFly.shared.appData.droneAlbumPreviewController!
            
            if(!dronePreviewController.userUsingSlider && dronePreviewController.isPlayingVideo){
                
                if(abs(dronePreviewController.videoCurrentTime - Double(state.playingPosition)) > 0.5 && state.playbackStatus == .stopped && state.playingPosition == 0){
                    dronePreviewController.previewLoading = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)){
                        CRFly.shared.droneController.pushCommand(command: StartDroneVideoPlayback(file: state.playingMedia))
                    }
                }
                dronePreviewController.videoCurrentTime = Double(state.playingPosition)
            }
        }
    }
}
