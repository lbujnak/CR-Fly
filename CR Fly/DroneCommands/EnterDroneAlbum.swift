import SwiftUI
import DJISDK

class LoadDroneAlbumCommand: DroneCommand {
    private var appData = CRFly.shared.appData
    
    func execute(completion: @escaping () -> Void) {
        if(!self.appData.djiDevConn){
            return
        }
        
        if(self.appData.djiDevice == nil){
            CRFly.shared.viewController.showSimpleAlert(title: "Error While Opening Photo Album", msg: Text("Application Data has incorrect drone instance"))
            completion()
            return
        }
        
        if(self.appData.djiDevice!.camera == nil){
            CRFly.shared.viewController.showSimpleAlert(title: "Error While Opening Photo Album", msg: Text("Unable to detect drone camera"))
            completion()
            return
        }
        
        let camera = self.appData.djiDevice!.camera!
        
        if(camera.displayName == DJICameraDisplayNameZenmuseP1 || camera.displayName == DJICameraDisplayNameMavicAir2Camera){
            camera.enterPlayback(completion: {(error) in
                if (error != nil) {
                    CRFly.shared.viewController.showSimpleAlert(title: "Error While Opening Photo Album", msg: Text(error!.localizedDescription))
                    completion()
                    return
                }
                print("***playback entered***")
                //load media
                completion()
            })
        } else{
            camera.setMode(.mediaDownload, withCompletion: {(error) in
                if(error != nil) {
                    CRFly.shared.viewController.showSimpleAlert(title: "Error While Opening Photo Album", msg: Text(error!.localizedDescription))
                    completion()
                    return
                }
                print("***playback entered***")
                //load media
                completion()
            })
        }
    }
    
    private func refreshMediaList(camera: DJICamera, completionHandler: @escaping (String?) -> Void){
        let manager = camera.mediaManager!
        manager.refreshFileList(of: DJICameraStorageLocation.sdCard, withCompletion: { (error) in
            if(error != nil){
                completionHandler("refresh error state: \(error!.localizedDescription)")
                return
            }
                
            let files : [DJIMediaFile] = manager.sdCardFileListSnapshot() ?? []
            self.appData.djiAlbumMedia.removeAll()
                    
            var sections = 0
            for i in 0..<files.count{
                if(i == 0 || self.appData.djiAlbumMedia[sections].last?.timeCreated.prefix(10) != files[i].timeCreated.prefix(10)){
                    self.appData.djiAlbumMedia.append([])
                    sections += 1
                }
                
                self.appData.djiAlbumMedia[sections-1].append(files[i])
            }
            completionHandler(nil)
                                    
            if(files.count > 0){
                self.downloadThumbnail(index: 0, retries: 0)
            }
        })
    }
}
