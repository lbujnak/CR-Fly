import DJISDK
import SwiftUI

/**
 `FetchDroneMedia` is a command class designed to handle the retrieval of media files from a DJI drone's camera media manager. This class is responsible for refreshing the list of media files stored on the drone's SD card, managing ongoing media downloads, and ensuring that the application's media album is updated accurately.
 
 - This command is executed when the application needs to update its local view of media files available on the drone's storage.
 - It checks for the current connection status of the drone and its camera, handles any ongoing media downloads by pausing them if necessary, and then proceeds to fetch the latest media file list from the drone.
 
 This class leverages functionality from the DJI SDK to interact with the drone's hardware and manage media files effectively, integrating these capabilities into a cohesive application workflow.
 */
public class FetchDroneMedia: Command {
    /// Reference to an instance of `DJIDroneController` that facilitates communication and control of the DJI drone.
    private let droneController = CRFly.shared.droneController as! DJIDroneController
    
    /// Reference to an instance of `AlbumDroneController` that manages the drone's album data and media playback states.
    private let albumDroneController = CRFly.shared.albumDroneController
    
    /// Executes the command that orchestrates the fetching of media files.
    public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        if !self.droneController.droneData.playbackMode {
            completion(true, false, nil)
        } else if self.droneController.djiDroneData.device == nil || 
                    self.droneController.djiDroneData.device!.camera == nil {
            completion(false, true, ("Error Refreshing Media List", "Connection to the drone was lost, or the camera could not be detected."))
        } else if self.droneController.droneData.mediaDownloadState != nil,
                    !self.droneController.droneData.mediaDownloadState!.transferPaused {
            
            // If a download is in progress, it must be paused before refreshing project list
            self.droneController.pushCommand(command: StopDroneMediaDownload(pauseOnly: true, forcePaused: true, withSuccessCompletion: { self.droneController.pushCommand(command: FetchDroneMedia()) }))
            completion(true, false, nil)
        } else {
            // Delegate droneController to receive updates of media playback
            self.droneController.djiDroneData.device!.camera!.mediaManager!.delegate = self.droneController
            self.albumDroneController.albumData.albumLoading = true
            
            // Fetch media list
            let manager = self.droneController.djiDroneData.device!.camera!.mediaManager!
            manager.refreshFileList(of: .sdCard, withCompletion: { error in
                if error != nil {
                    completion(false, true, ("Error Refreshing Media List", error!.localizedDescription))
                } else {
                    let files: [DJIMediaFile] = manager.sdCardFileListSnapshot() ?? []
                    
                    self.albumDroneController.cleanAlbum()
                    self.albumDroneController.addToAlbum(files: files.reversed())
                    
                    // Start a download process
                    if self.droneController.droneData.mediaDownloadState != nil, self.droneController.droneData.mediaDownloadState!.transferForcePaused {
                        self.droneController.pushCommand(command: StartDroneMediaDownload(files: []))
                    }
                    
                    completion(true, false, nil)
                }
                self.albumDroneController.albumData.albumLoading = false
            })
        }
    }
}
