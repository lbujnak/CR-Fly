import SwiftUI
import DJISDK

class FetchDroneMedia: Command {
    let downloadRetries = 3
    
    private var albumController: DroneAlbumController
    private var appData = CRFly.shared.appData
    
    init(albumController: DroneAlbumController){
        self.albumController = albumController
    }
    
    func execute(completion: @escaping () -> Void) {
        if(!self.appData.djiDevConn){
            completion()
            return
        }
        
        if(self.appData.djiDevice == nil || self.appData.djiDevice!.camera == nil){
            CRFly.shared.viewController.showSimpleAlert(title: "Error While Downloading Thumbnails", msg: Text("Lost connection to drone or cant detect camera"))
            completion()
            return
        }
        
        self.appData.djiDevice!.camera!.mediaManager!.delegate = CRFly.shared.droneController
        
        let manager = self.appData.djiDevice!.camera!.mediaManager!
        manager.refreshFileList(of: DJICameraStorageLocation.sdCard, withCompletion: { (error) in
            if(error != nil){
                CRFly.shared.viewController.showSimpleAlert(title: "Error While Downloading Thumbnails", msg: Text(error!.localizedDescription))
            } else {
                let files : [DJIMediaFile] = manager.sdCardFileListSnapshot() ?? []
                if(files.count != 0) {
                    self.albumController.albumLoading = true
                    if(!self.albumController.albumItems.values.flatMap{ $0 }.elementsEqual(files)){
                        self.albumController.cleanAlbum()
                        self.fetchMediaThumbnails(files: files.reversed(), index: 0, retriesLeft: self.downloadRetries) {
                            completion()
                        }
                    }
                }
            }
        })
    }
    
    func fetchMediaThumbnails(files: [DJIMediaFile], index: Int, retriesLeft: Int, doAfter: @escaping () -> Void) {
        if(CRFly.shared.viewController.getViewType() != .albumView){
            self.albumController.albumLoading = false
            doAfter()
            return
        }
        if(index >= files.count) {
            doAfter()
            return
        }
        
        let photoOrPano = self.albumController.isPhoto(file: files[index]) || self.albumController.isPano(file: files[index])
        
        if((self.albumController.isVideo(file: files[index]) && files[index].thumbnail != nil) || (photoOrPano && files[index].preview != nil)){
            self.albumController.addToAlbum(file: files[index])
            self.fetchMediaThumbnails(files: files, index: index+1, retriesLeft: retriesLeft, doAfter: doAfter)
            return
        }
        
        if(self.albumController.isVideo(file: files[index])){
            files[index].fetchThumbnail() { (error) in
                self.checkAddPreview(error: error, files: files, index: index, retriesLeft: retriesLeft, doAfter: doAfter)
            }
        } else if(photoOrPano){
            files[index].fetchPreview() { (error) in
                self.checkAddPreview(error: error, files: files, index: index, retriesLeft: retriesLeft, doAfter: doAfter)
            }
        }
    }
    
    private func checkAddPreview(error: Error?, files: [DJIMediaFile], index: Int, retriesLeft: Int, doAfter: @escaping () -> Void){
        if(error != nil ) {
            if(retriesLeft != 0){
                sleep(2)
                self.fetchMediaThumbnails(files: files, index: index, retriesLeft: retriesLeft-1, doAfter: doAfter)
            } else {
                CRFly.shared.viewController.showSimpleAlert(title: "Error While Downloading Thumbnails", msg: Text(error!.localizedDescription))
                self.albumController.albumLoading = false
                doAfter()
            }
            return
        }
        self.albumController.addToAlbum(file: files[index])
        self.fetchMediaThumbnails(files: files, index: index+1, retriesLeft: retriesLeft, doAfter: doAfter)
    }
}
