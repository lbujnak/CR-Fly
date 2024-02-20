import SwiftUI
import DJISDK

class RemoveDroneMedia: DroneCommand {
    var files: [DJIMediaFile]
    
    private var appData = CRFly.shared.appData
    
    init(files: [DJIMediaFile]) {
        self.files = files
    }
    
    func execute(completion: @escaping () -> Void) {
        self.appData.mediaAlbumLoading = true
        if(self.appData.djiDevice == nil || self.appData.djiDevice!.camera == nil){
            CRFly.shared.viewController.showSimpleAlert(title: "Error While Removing Files", msg: Text("Lost connection to drone or cant detect camera"))
            self.appData.mediaAlbumLoading = false
            completion()
            return
        }
        
        self.appData.djiDevice!.camera!.mediaManager?.delete(files, withCompletion: {(failedFiles, error) in
            if(error != nil || failedFiles.count != 0){
                CRFly.shared.viewController.showSimpleAlert(title: "(\(failedFiles.count)) file(s) Were Not Removed", msg: Text(String(describing: error!)))
            }
            CRFly.shared.droneController.pushCommand(command: FetchDroneMedia())
            completion()
        })
    }
}
