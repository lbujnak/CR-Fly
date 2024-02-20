import SwiftUI
import DJISDK

class FetchDronePreview: DroneCommand {
    var file: DJIMediaFile
    
    init(file: DJIMediaFile) {
        self.file = file
    }
    
    func execute(completion: @escaping () -> Void) {
        self.file.fetchPreview(completion: {(error) in
            if(error != nil){
                CRFly.shared.viewController.showSimpleAlert(title: "Error Preparing Preview", msg: Text("Error downloading preview from drone: \(String(describing: error!))"))
                return
            }
            CRFly.shared.appData.djiMediaPreviewState = MediaDronePreviewState(media: self.file, currentTime: 0, isPlaying: false, isPreparing: false, isUserChangingTime: false, totalTime: 0)
        })
        completion()
    }
}
