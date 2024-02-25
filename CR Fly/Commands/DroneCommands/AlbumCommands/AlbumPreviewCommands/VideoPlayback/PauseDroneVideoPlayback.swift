import SwiftUI
import DJISDK

class PauseDroneVideoPlayback: Command {
    private var appData = CRFly.shared.appData
    
    func execute(completion: @escaping () -> Void) {
        if(self.appData.djiDevice == nil || self.appData.djiDevice!.camera == nil){
            CRFly.shared.viewController.showSimpleAlert(title: "Error While Pausing Video Preview", msg: Text("Lost connection to drone or cant detect camera"))
            completion()
            return
        }
        
        if(self.appData.droneAlbumPreviewController == nil){
            completion()
            return
        }
        
        self.appData.djiDevice!.camera!.mediaManager!.pause(completion: {(error) in
            if(error != nil) {
                CRFly.shared.viewController.showSimpleAlert(title: "Error While Pausing Video Preview", msg: Text("Couldn't pause video"))
            } else {
                self.appData.droneAlbumPreviewController?.isPlayingVideo = false
            }
            completion()
        })
    }
}
