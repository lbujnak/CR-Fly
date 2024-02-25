import SwiftUI
import DJISDK

class StartDroneVideoPlayback: Command {
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
            
            if(self.appData.droneAlbumPreviewController == nil){
                self.appData.djiDevice!.camera!.mediaManager!.stop()
            } else {
                self.appData.droneAlbumPreviewController!.videoCurrentTime = 0
                self.appData.droneAlbumPreviewController!.videoTotalTime = Double(self.file.durationInSeconds)
                self.appData.droneAlbumPreviewController!.previewLoading = false
                self.appData.droneAlbumPreviewController!.isPlayingVideo = true
            }
            completion()
        })
    }
}
