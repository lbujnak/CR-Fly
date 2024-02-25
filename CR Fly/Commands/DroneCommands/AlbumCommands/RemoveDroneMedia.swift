import SwiftUI
import DJISDK

class RemoveDroneMedia: Command {
    var files: [DJIMediaFile]
    
    private var albumController: DroneAlbumController
    private var appData = CRFly.shared.appData
    
    init(files: [DJIMediaFile], albumController: DroneAlbumController) {
        self.files = files
        self.albumController = albumController
    }
    
    func execute(completion: @escaping () -> Void) {
        if(!self.appData.djiDevConn){ return }
        
        if(self.appData.djiDevice == nil || self.appData.djiDevice!.camera == nil){
            CRFly.shared.viewController.showSimpleAlert(title: "Error While Removing Files", msg: Text("Lost connection to drone or cant detect camera"))
            completion()
            return
        }
        
        self.albumController.albumLoading = true
        self.appData.djiDevice!.camera!.mediaManager?.delete(files, withCompletion: {(failedFiles, error) in
            if(error != nil || failedFiles.count != 0){
                self.albumController.albumLoading = false
                CRFly.shared.viewController.showSimpleAlert(title: "(\(failedFiles.count)) file(s) Were Not Removed", msg: Text(String(describing: error!)))
            }
            CRFly.shared.droneController.pushCommand(command: FetchDroneMedia(albumController: self.albumController))
            completion()
        })
    }
}
