import Foundation
import DJISDK

public class CRFly: ObservableObject {
    static var shared = CRFly()

    //Data
    @Published var appData = ApplicationData()
    
    //Controllers
    @Published var viewController = ViewController()
    @Published var droneController = DroneController()
    @Published var droneAlbumController = DroneAlbumController()
    @Published var savedAlbumController = SavedAlbumController()
    
    public func updateDroneDownloadSpeed(lastBytesCnt: Int64) {
        if(self.appData.mediaDownloadState != nil) {
            let downloaded = self.appData.mediaDownloadState!.downloadedBytes
            let realByteCnt : Int64 = downloaded - lastBytesCnt
            let newSpeed = Float(realByteCnt) / 1000000
            
            self.appData.mediaDownloadState!.downloadSpeed = newSpeed
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)){
                self.updateDroneDownloadSpeed(lastBytesCnt: downloaded)
            }
        }
    }
}
