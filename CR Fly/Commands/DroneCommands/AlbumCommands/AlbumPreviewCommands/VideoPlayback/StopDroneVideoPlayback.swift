import SwiftUI
import DJISDK

class StopDroneVideoPlayback: Command {
    private var appData = CRFly.shared.appData
    
    func execute(completion: @escaping () -> Void) {
        if(self.appData.djiDevice == nil || self.appData.djiDevice!.camera == nil){
            CRFly.shared.viewController.showSimpleAlert(title: "Error While Stopping Video Playback", msg: Text("Lost connection to drone or cant detect camera"))
            completion()
            return
        }
        
        self.appData.djiDevice!.camera!.mediaManager!.stop()
        completion()
    }
}
