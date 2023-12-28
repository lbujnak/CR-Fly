import SwiftUI
import DJISDK

class DownloadDronePreview: DroneCommand {
    let downloadRetries = 3
    
    private var appData = CRFly.shared.appData
    private var mediaFetchError: Bool = false
    
    func execute(completion: @escaping () -> Void) {
        if(self.appData.djiDevice == nil || self.appData.djiDevice!.camera == nil){
            CRFly.shared.viewController.showSimpleAlert(title: "Error While Downloading Thumbnails", msg: Text("Lost connection to drone or cant detect camera"))
            completion()
            return
        }
        
        let manager = self.appData.djiDevice!.camera!.mediaManager!
        manager.refreshFileList(of: DJICameraStorageLocation.sdCard, withCompletion: { (error) in
            if(error != nil){
                CRFly.shared.viewController.showSimpleAlert(title: "Error While Downloading Thumbnails", msg: Text(error!.localizedDescription))
            } else {
                let files : [DJIMediaFile] = manager.sdCardFileListSnapshot() ?? []
                self.appData.djiAlbumMedia.removeAll()
                self.downloadThumbnail(files: files.reversed(), index: 0, retriesLeft: 3)
            }
            completion()
        })
    }
    
    private func downloadThumbnail(files: [DJIMediaFile], index: Int, retriesLeft: Int){
        if(CRFly.shared.viewController.getViewType() != .albumView){ return }
        if(index >= files.count) { return }
        
        if(files[index].thumbnail != nil){
            self.addMediaToAppData(file: files[index])
            self.downloadThumbnail(files: files, index: index+1, retriesLeft: retriesLeft)
            return
        }
            
        files[index].fetchThumbnail(completion: { (error) in
            if(error != nil ) {
                if(retriesLeft != 0){
                    sleep(2)
                    self.downloadThumbnail(files: files, index: index, retriesLeft: retriesLeft-1)
                } else {
                    CRFly.shared.viewController.showSimpleAlert(title: "Error While Downloading Thumbnails", msg: Text(error!.localizedDescription))
                }
                return
            }
            self.addMediaToAppData(file: files[index])
            self.downloadThumbnail(files: files, index: index+1, retriesLeft: retriesLeft)
        })
    }
    
    private func addMediaToAppData(file: DJIMediaFile){
        let fileDateString = String(file.timeCreated.prefix(10))
        let fileDate = SimpleDateFormatter().date(from: fileDateString)
        
        if let _ = self.appData.djiAlbumMedia[fileDate!] {
            self.appData.djiAlbumMedia[fileDate!]!.append(file)
        } else {
            self.appData.djiAlbumMedia[fileDate!] = [file]
        }
    }
}
