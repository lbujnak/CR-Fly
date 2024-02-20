import SwiftUI
import DJISDK

class ChangeVideoTimeDronePlayback: DroneCommand {
    private var appData = CRFly.shared.appData
    
    func execute(completion: @escaping () -> Void) {
        if(self.appData.djiMediaPreviewState!.currentTime == self.appData.djiMediaPreviewState!.totalTime){
            CRFly.shared.droneController.pushCommand(command: PrepareDroneVideoPlayback(file: self.appData.djiMediaPreviewState!.media))
            completion()
            return
        }
        
        if(self.appData.djiDevice == nil || self.appData.djiDevice!.camera == nil){
            CRFly.shared.viewController.showSimpleAlert(title: "Error While Changing Drone Video Time", msg: Text("Lost connection to drone or can't detect camera"))
            completion()
            return
        }
        
        if(self.appData.djiMediaPreviewState == nil) {
            completion()
            return
        }
        
        self.appData.djiDevice!.camera!.mediaManager!.move(toPosition: Float(self.appData.djiMediaPreviewState!.currentTime), withCompletion: {(error) in
            if(error != nil){
                CRFly.shared.viewController.showSimpleAlert(title: "Error While Changing Drone Video Time", msg: Text("Couldn't change video time: \(String(describing: error!))"))
                completion()
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)){
                if(!self.appData.djiMediaPreviewState!.isPlaying){
                    self.appData.djiDevice!.camera!.mediaManager!.pause(completion: { (error) in
                        if(error != nil) {
                            CRFly.shared.viewController.showSimpleAlert(title: "Error While Changing Drone Video Time", msg: Text("Couldn't pause video: \(String(describing: error!))"))
                        }
                        self.appData.djiMediaPreviewState!.isUserChangingTime = false
                        completion()
                    })
                }
                else {
                    self.appData.djiMediaPreviewState!.isUserChangingTime = false
                    completion()
                }
            }
        })
    }
}
