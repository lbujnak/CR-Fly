import SwiftUI
import DJISDK

class EnterDroneAlbum: DroneCommand {
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
                } else {
                    print("***playback entered***")
                    CRFly.shared.droneController.pushCommand(command: FetchDroneMedia())
                }
                completion()
            })
        } else{
            camera.setMode(.mediaDownload, withCompletion: {(error) in
                if(error != nil) {
                    CRFly.shared.viewController.showSimpleAlert(title: "Error While Opening Photo Album", msg: Text(error!.localizedDescription))
                } else {
                    print("***playback entered***")
                    CRFly.shared.droneController.pushCommand(command: FetchDroneMedia())
                }
                completion()
            })
        }
    }
}
