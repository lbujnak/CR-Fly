import DJISDK
import SwiftUI

/**
 `FetchDroneThumbnail` is a command class responsible for fetching media thumbnail from DJI drones.
 
 - This command is typically used when updating the drone's album view in the application, especially after new media is detected or when the user manually refreshes the media list.
 - It ensures that media files have the necessary previews for a user-friendly display, fetching missing thumbnails and previews as required.
 
 This class leverages functionality from the DJI SDK to interact with the drone's hardware and manage media files effectively, integrating these capabilities into a cohesive application workflow.
 */
public class FetchDroneThumbnail: Command {
    /// Reference to an instance of `DJIDroneController` that facilitates communication and control of the DJI drone.
    private let droneController = CRFly.shared.droneController as! DJIDroneController
    
    /// Reference to an instance of `AlbumDroneController` that manages the drone's album data and media playback states.
    private let albumDroneController = CRFly.shared.albumDroneController
    
    /// A `DJIMediaFile` object representing the media file for which thumbnail is to be fetched.
    private let file: DJIMediaFile
    
    /// Initializes the command with the specified files, index, and run identifier.
    public init(file: DJIMediaFile) {
        self.file = file
    }
    
    /// Begins the process of fetching media previews, ensuring that only the relevant fetch sequence is active and updating the album as necessary.
    public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        if !self.file.valid || self.file.thumbnail != nil || !self.droneController.droneData.playbackMode {
            completion(true, false, nil)
            return
        }
        
        // If a download is in progress, it must be paused before thumbnail fetching
        if self.droneController.droneData.mediaDownloadState != nil, !self.droneController.droneData.mediaDownloadState!.transferPaused {
            self.droneController.prependCommand(command: FetchDroneThumbnail(file: self.file))
            self.droneController.prependCommand(command: StopDroneMediaDownload(pauseOnly: true, forcePaused: true))
        } else {
            self.albumDroneController.albumDroneData.previewFetching = true
            self.file.fetchThumbnail { error in
                self.albumDroneController.albumDroneData.previewFetching = false
                
                if error != nil {
                    completion(false, true, ("Error Downloading Media Thumbnail", error!.localizedDescription))
                    return
                }
                
                // Start a download process
                if !self.albumDroneController.albumDroneData.showingThumbnail.contains(where: { $0.thumbnail == nil }), self.droneController.droneData.mediaDownloadState != nil {
                    self.droneController.pushCommand(command: StartDroneMediaDownload())
                }
            }
        }
        completion(true, false, nil)
    }
}
