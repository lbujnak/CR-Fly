import SwiftUI
import DJISDK

class EnterDroneAlbum: Command {
    private var albumController: DroneAlbumController
    private var appData = CRFly.shared.appData
    
    init(albumController: DroneAlbumController){
        self.albumController = albumController
    }
    
    func execute(completion: @escaping () -> Void) {
        if(!self.appData.djiDevConn || self.appData.mediaDownloadState != nil){
            completion()
            return
        }
        
        if(self.appData.djiDevice == nil || self.appData.djiDevice!.camera == nil){
            CRFly.shared.viewController.showSimpleAlert(title: "Error While Downloading Thumbnails", msg: Text("Lost connection to drone or cant detect camera"))
            completion()
            return
        }
        
        let camera = self.appData.djiDevice!.camera!
        
        if(camera.displayName == DJICameraDisplayNameZenmuseP1 || camera.displayName == DJICameraDisplayNameMavicAir2Camera){
            camera.enterPlayback(completion: {(error) in
                if (error != nil) {
                    CRFly.shared.viewController.showSimpleAlert(title: "Error While Opening Photo Album", msg: Text(error!.localizedDescription))
                } else {
                    CRFly.shared.droneController.pushCommand(command: FetchDroneMedia(albumController: self.albumController))
                }
                completion()
            })
        } else{
            camera.setMode(.mediaDownload, withCompletion: {(error) in
                if(error != nil) {
                    CRFly.shared.viewController.showSimpleAlert(title: "Error While Opening Photo Album", msg: Text(error!.localizedDescription))
                } else {
                    CRFly.shared.droneController.pushCommand(command: FetchDroneMedia(albumController: self.albumController))
                }
                completion()
            })
        }
    }
}
