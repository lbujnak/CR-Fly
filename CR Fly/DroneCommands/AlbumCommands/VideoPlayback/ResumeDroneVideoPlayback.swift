import SwiftUI
import DJISDK

class ResumeDroneVideoPlayback: DroneCommand {
    private var appData = CRFly.shared.appData
    
    func execute(completion: @escaping () -> Void) {
        if(self.appData.djiDevice == nil || self.appData.djiDevice!.camera == nil){
            CRFly.shared.viewController.showSimpleAlert(title: "Error While Resuming Video Preview", msg: Text("Lost connection to drone or cant detect camera"))
            completion()
            return
        }
        
        self.appData.djiDevice!.camera!.mediaManager!.resume(completion: {(error) in
            if(error != nil) {
                CRFly.shared.viewController.showSimpleAlert(title: "Error While Resuming Video Preview", msg: Text("Couldn't resume video"))
            } else {
                if(self.appData.djiMediaPreviewState != nil) {
                    self.appData.djiMediaPreviewState!.isPlaying = true
                }
            }
            completion()
        })
    }
}
