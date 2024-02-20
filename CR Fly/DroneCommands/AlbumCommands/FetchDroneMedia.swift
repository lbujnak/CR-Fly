import SwiftUI
import DJISDK

class FetchDroneMedia: DroneCommand {
    let downloadRetries = 3
    
    private var appData = CRFly.shared.appData
    
    func execute(completion: @escaping () -> Void) {
        self.appData.mediaSavedAlbum.removeAll()
        self.appData.mediaAlbumLoading = true
        if(self.appData.djiDevice == nil || self.appData.djiDevice!.camera == nil){
            CRFly.shared.viewController.showSimpleAlert(title: "Error While Downloading Thumbnails", msg: Text("Lost connection to drone or cant detect camera"))
            self.appData.mediaAlbumLoading = false
            completion()
            return
        }
        
        self.appData.djiDevice!.camera!.mediaManager!.delegate = CRFly.shared.droneController
        
        let manager = self.appData.djiDevice!.camera!.mediaManager!
        manager.refreshFileList(of: DJICameraStorageLocation.sdCard, withCompletion: { (error) in
            if(error != nil){
                CRFly.shared.viewController.showSimpleAlert(title: "Error While Downloading Thumbnails", msg: Text(error!.localizedDescription))
                    self.appData.mediaAlbumLoading = false
            } else {
                let files : [DJIMediaFile] = manager.sdCardFileListSnapshot() ?? []
                self.fetchMediaThumbnails(files: files.reversed(), index: 0, retriesLeft: self.downloadRetries) {
                    completion()
                }
            }
        })
    }
    
    func fetchMediaThumbnails(files: [DJIMediaFile], index: Int, retriesLeft: Int, doAfter: @escaping () -> Void) {
        if(CRFly.shared.viewController.getViewType() != .albumView){
            self.appData.mediaAlbumLoading = false
            doAfter()
            return
        }
        if(index >= files.count) {
            self.appData.mediaAlbumLoading = false
            doAfter()
            return
        }
            
        if(files[index].thumbnail != nil){
            self.addMediaToAppData(file: files[index])
            self.fetchMediaThumbnails(files: files, index: index+1, retriesLeft: retriesLeft, doAfter: doAfter)
            return
        }
        
        files[index].fetchThumbnail() { (error) in
            if(error != nil ) {
                if(retriesLeft != 0){
                    sleep(2)
                    self.fetchMediaThumbnails(files: files, index: index, retriesLeft: retriesLeft-1, doAfter: doAfter)
                } else {
                    CRFly.shared.viewController.showSimpleAlert(title: "Error While Downloading Thumbnails", msg: Text(error!.localizedDescription))
                    self.appData.mediaAlbumLoading = false
                    doAfter()
                }
                return
            }
            self.addMediaToAppData(file: files[index])
            self.fetchMediaThumbnails(files: files, index: index+1, retriesLeft: retriesLeft, doAfter: doAfter)
        }
    }
        
    private func addMediaToAppData(file: DJIMediaFile){
        let fileDateString = String(file.timeCreated.prefix(10))
        let fileDate = SimpleDateFormatter().date(from: fileDateString)!
        
        if let _ = self.appData.djiMediaAlbum[fileDate] {
            self.appData.djiMediaAlbum[fileDate]!.append(file)
        } else {
            self.appData.djiMediaAlbum[fileDate] = [file]
        }
    }
}
