import SwiftUI
import DJISDK

class DroneController: NSObject {
    
    private var isExecutingCommand = false
    private var commandQueue: [DroneCommand] = []
    
    //MARK: Drone Command Queue
    func pushCommand(command: DroneCommand) {
        commandQueue.append(command)
        if(!isExecutingCommand) {
            processNextCommand()
        }
    }
    
    private func processNextCommand() {
        guard !isExecutingCommand, !commandQueue.isEmpty else { return }

        isExecutingCommand = true
        let command = commandQueue.removeFirst()
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
    
    private func droneDisconnected(){
        self.commandQueue.removeAll()
        CRFly.shared.appData.djiDevConn = false
        CRFly.shared.appData.djiDevice = nil
        CRFly.shared.appData.djiMediaAlbum = [:]
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
            CRFly.shared.appData.djiDevice = DJISDKManager.product()
            CRFly.shared.appData.djiDevConn = true
            
            if(CRFly.shared.viewController.getViewType() == .albumView) {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)){
                    CRFly.shared.droneController.pushCommand(command: EnterDroneAlbum())
                }
            }
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
        let appData = CRFly.shared.appData
        //Update time of video preview
        if(appData.djiMediaPreviewState != nil) {
            if(!appData.djiMediaPreviewState!.isUserChangingTime && appData.djiMediaPreviewState!.isPlaying){
                appData.djiMediaPreviewState!.currentTime = state.playingPosition
                
                if(state.playbackStatus == .stopped && state.playingPosition == 0) {
                    appData.djiMediaPreviewState = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)){
                        CRFly.shared.droneController.pushCommand(command: PrepareDroneVideoPlayback(file: state.playingMedia))
                    }
                }
            }
        }
    }
}
