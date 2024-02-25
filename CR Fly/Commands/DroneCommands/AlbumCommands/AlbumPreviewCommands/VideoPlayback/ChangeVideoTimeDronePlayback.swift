import SwiftUI
import DJISDK

class ChangeVideoTimeDronePlayback: Command {
    var file: DJIMediaFile
    private var appData = CRFly.shared.appData
    
    init(file: DJIMediaFile) {
        self.file = file
    }
    
    func execute(completion: @escaping () -> Void) {
        if(self.appData.droneAlbumPreviewController == nil){
            completion()
            return
        }
        
        if(self.appData.droneAlbumPreviewController!.videoCurrentTime == self.appData.droneAlbumPreviewController!.videoTotalTime){
            self.appData.droneAlbumPreviewController!.videoCurrentTime = 0
        }
        
        if(self.appData.djiDevice == nil || self.appData.djiDevice!.camera == nil){
            CRFly.shared.viewController.showSimpleAlert(title: "Error While Changing Drone Video Time", msg: Text("Lost connection to drone or can't detect camera"))
            completion()
            return
        }
        
        self.appData.djiDevice!.camera!.mediaManager!.move(toPosition: Float(self.appData.droneAlbumPreviewController!.videoCurrentTime), withCompletion: {(error) in
            if(error != nil){
                CRFly.shared.viewController.showSimpleAlert(title: "Error While Changing Drone Video Time", msg: Text("Couldn't change video time: \(String(describing: error!))"))
                completion()
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)){
                if(self.appData.droneAlbumPreviewController == nil){
                    completion()
                    return
                }
                
                if(!self.appData.droneAlbumPreviewController!.isPlayingVideo){
                    self.appData.djiDevice!.camera!.mediaManager!.pause(completion: { (error) in
                        if(error != nil) {
                            CRFly.shared.viewController.showSimpleAlert(title: "Error While Changing Drone Video Time", msg: Text("Couldn't pause video: \(String(describing: error!))"))
                        }
                        self.appData.droneAlbumPreviewController?.userUsingSlider = false
                        completion()
                    })
                }
                else {
                    self.appData.droneAlbumPreviewController?.userUsingSlider = false
                    completion()
                }
            }
        })
    }
}
