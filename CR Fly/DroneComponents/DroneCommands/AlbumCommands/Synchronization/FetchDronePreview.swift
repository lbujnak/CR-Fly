import DJISDK
import SwiftUI

/**
 `FetchDronePreview` is a command class responsible for fetching media previews from DJI drones.
 
 - This command is typically used when updating the drone's album view in the application, especially after new media is detected or when the user manually refreshes the media list.
 - It ensures that media files have the necessary previews for a user-friendly display, fetching missing previews as required.
 
 This class leverages functionality from the DJI SDK to interact with the drone's hardware and manage media files effectively, integrating these capabilities into a cohesive application workflow.
 */
public class FetchDronePreview: Command {
    /// Reference to an instance of `DJIDroneController` that facilitates communication and control of the DJI drone.
    private let droneController = CRFly.shared.droneController as! DJIDroneController
    
    /// Reference to an instance of `AlbumDroneController` that manages the drone's album data and media playback states.
    private let albumPreviewData = CRFly.shared.albumDroneController.albumData.albumPreviewController?.albumPreviewData
    
    private let file: DJIMediaFile
    
    /// Initializes the command with the specified files, index, and run identifier.
    public init(file: DJIMediaFile) {
        self.file = file
    }
    
    /// Begins the process of fetching media previews, ensuring that only the relevant fetch sequence is active and updating the album as necessary.
    public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        if !self.droneController.droneData.playbackMode || self.albumPreviewData == nil {
            completion(true, false, nil)
            return
        }
        
        if self.file.preview != nil { 
            self.albumPreviewData!.previewLoading = false
        }
        else {
            // If a download is in progress, it must be paused before fetching preview
            if self.droneController.droneData.mediaDownloadState != nil, !self.droneController.droneData.mediaDownloadState!.transferPaused {
                self.droneController.pushCommand(command: StopDroneMediaDownload(pauseOnly: true, forcePaused: true, withSuccessCompletion: {
                    self.droneController.pushCommand(command: FetchDronePreview(file: self.file))
                }))
            } else {
                self.file.fetchPreview() { error in
                    if error != nil {
                        completion(false, true, ("Error Downloading Media Preview", error!.localizedDescription))
                        return
                    } else {
                        self.albumPreviewData!.previewLoading = false
                        
                        // Start a download process
                        if self.droneController.droneData.mediaDownloadState != nil, self.droneController.droneData.mediaDownloadState!.transferForcePaused {
                            self.droneController.pushCommand(command: StartDroneMediaDownload(files: []))
                        }
                    }
                }
            }
        }
        completion(true, false, nil)
    }
}
