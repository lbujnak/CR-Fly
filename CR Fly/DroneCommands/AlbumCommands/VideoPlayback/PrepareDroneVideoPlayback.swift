import SwiftUI
import DJISDK

class PrepareDroneVideoPlayback: DroneCommand {
    var file: DJIMediaFile
    private var appData = CRFly.shared.appData
    
    init(file: DJIMediaFile) {
        self.file = file
    }
    
    func execute(completion: @escaping () -> Void) {
        if(self.appData.djiDevice == nil || self.appData.djiDevice!.camera == nil){
            CRFly.shared.viewController.showSimpleAlert(title: "Error While Starting Video Preview", msg: Text("Lost connection to drone or cant detect camera"))
            completion()
            return
        }
        
        self.appData.djiDevice!.camera!.mediaManager!.playVideo(self.file, withCompletion: {(error) in
            if(error != nil) {
                CRFly.shared.viewController.showSimpleAlert(title: "Error While Starting Video Preview", msg: Text("Couldn't play video. Error: \(String(describing: error!))"))
                completion()
                return
            }
            
            self.appData.djiDevice!.camera!.mediaManager!.move(toPosition: 0, withCompletion: {(error) in
                if(error != nil){
                    CRFly.shared.viewController.showSimpleAlert(title: "Error While Starting Video Preview", msg: Text("Couldn't start video from beggining: \(String(describing: error!))"))
                    completion()
                    return
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)){
                    self.appData.djiDevice!.camera!.mediaManager!.pause(completion: { (error) in
                        if(error != nil) {
                            CRFly.shared.viewController.showSimpleAlert(title: "Error While Starting Video Preview", msg: Text("Couldn't stop video playback: \(String(describing: error!))"))
                        }
                        self.appData.djiMediaPreviewState = MediaDronePreviewState(media: self.file, currentTime: 0, isPlaying: false, isPreparing: false, isUserChangingTime: false, totalTime: self.file.durationInSeconds)
                        completion()
                    })
                }
            })
        })
    }
}
