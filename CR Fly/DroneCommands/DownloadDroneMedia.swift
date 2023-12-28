import SwiftUI
import DJISDK

class SaveDroneMedia: DroneCommand {
    private var selectedItems : Array<DJIMediaFile>
    
    private var appData = CRFly.shared.appData
    
    init(selectedItems: Array<DJIMediaFile>) {
        self.selectedItems = selectedItems
    }
    
    func execute(completion: @escaping () -> Void) {
        if(self.appData.mediaDownloadState != nil) {
            CRFly.shared.viewController.showSimpleAlert(title: "Error While Saving Media", msg: Text("Unexpected Error. Download of full-resolution media is already in progress."))
        }
        
        var totalBytes: Int64 = 0
        
        for file in self.selectedItems {
            totalBytes += file.fileSizeInBytes
            if(self.mediaSaved(file: file)){
                if(self.rcProjectManager.mediaUploading){
                    let url = URL(fileURLWithPath: self.libraryURL.relativePath).appendingPathComponent(file.fileName)
                    self.rcProjectManager.sendSingleImage(path: url){ error in
                        if(error != nil){
                            GlobalAlertHelper.shared.createAlert(title: "Upload Error", msg: "Couldn't continue in upload, error: \(error!)")
                        }
                    }
                }
            } else {
                self.mediaDownloadList.append(file)
            }
        }
                
        if(self.mediaDownloadList.count > 0) {
            self.mediaDownloading = true
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)){
                self.saveMediaToDevice(position: 0)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)){
                self.updateTransSpeed(lastBytes: 0)
            }
        }
    }
}
