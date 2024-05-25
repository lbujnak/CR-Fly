import DJISDK
import SwiftUI

/**
 `RemoveDroneMedia` is a command class that facilitates the removal of media files from DJI drones. It ensures that operations respect the current state of the system, specifically whether files are being downloaded.
 
 - The class is typically used when a user needs to clear space or organize files directly on the drone's storage.
 - It interacts with the DJI SDK's media manager to execute file deletions and provides feedback through the completion handler.
 
 - Note: This class includes robust error handling to deal with various scenarios like lost drone connections or files being actively downloaded.
 The class can be configured to ignore download states, which is useful in scenarios where immediate file removal is necessary regardless of the download state.
 */
public class RemoveDroneMedia: Command {
    /// Reference to the `ViewController` responsible for managing navigation, presentation of different views within the application and displaying errors.
    private let viewController = CRFly.shared.viewController
    
    /// Reference to an instance of `DJIDroneController` that facilitates communication and control of the DJI drone.
    private let droneController = CRFly.shared.droneController as! DJIDroneController
    
    /// Reference to an instance of `AlbumDroneController` that manages the drone's album data and media playback states.
    private let albumDroneController = CRFly.shared.albumDroneController
    
    /// An array of `DJIMediaFile` objects representing the files to be removed.
    private let files: [DJIMediaFile]
    
    /// A boolean that, if true, allows removal of files even if they are part of an ongoing download operation.
    private let overrideDownloadCheck: Bool
    
    /// Initializes the command with the specified files and an optional parameter to override the download check. This allows the command to remove files that are currently being downloaded if set to true.
    public init(files: [DJIMediaFile], overrideDownloadCheck: Bool = false) {
        self.files = files
        self.overrideDownloadCheck = overrideDownloadCheck
    }
    
    /// Conducts the file removal operation. It checks if the files are currently being downloaded and if the drone is connected. It handles user confirmation for removing files that are being downloaded.
    public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        if self.droneController.djiDroneData.device == nil || self.droneController.djiDroneData.device!.camera == nil {
            completion(false, true, ("Error Removing File", "Connection to the drone was lost, or the camera could not be detected."))
        } else if self.droneController.droneData.mediaDownloadState != nil {
            var fileCheck: [DJIMediaFile] = []
            if self.droneController.droneData.mediaDownloadState != nil {
                for file in self.files {
                    if self.droneController.droneData.mediaDownloadState!.downloadSet.contains(file) {
                        fileCheck.append(file)
                    }
                }
            }
            
            // Checks if there is ongoing download on file in remove list. If yes, user will be notified and required to submit this removal
            if !self.overrideDownloadCheck {
                if !fileCheck.isEmpty {
                    self.viewController.showAlert(
                        title: "Remove Media Alert",
                        msg: Text("It appears that you are attempting to remove \(fileCheck.count) file(s) currently in the process of being downloaded. Are you sure you want to proceed with the removal?"),
                        buttons: [
                            (label: "Confirm", action: {
                                self.droneController.pushCommand(command: RemoveDroneMedia(files: self.files, overrideDownloadCheck: true))
                            }), (label: "Cancel", action: {})
                        ])
                    completion(true, false, nil)
                    return
                }
            }
            
            // If a download is in progress, it must be paused before removing media
            if !self.droneController.droneData.mediaDownloadState!.transferPaused {
                self.droneController.pushCommand(command: StopDroneMediaDownload(pauseOnly: true, forcePaused: true, withSuccessCompletion: {
                    self.droneController.pushCommand(command: RemoveDroneMedia(files: self.files, overrideDownloadCheck: self.overrideDownloadCheck))
                }))
                completion(true, false, nil)
                return
                // Substract remove media list from MediaDownloadState
            } else {
                if self.droneController.droneData.mediaDownloadState != nil {
                    for file in fileCheck {
                        if self.droneController.droneData.mediaDownloadState!.downloadSet.contains(file) {
                            self.droneController.droneData.mediaDownloadState!.totalBytes -= UInt(file.fileSizeInBytes)
                            self.droneController.droneData.mediaDownloadState!.totalMedia -= 1
                            self.droneController.droneData.mediaDownloadState!.downloadSet.remove(file)
                        }
                    }
                }
            }
        }
        
        // Continue with removal
        self.albumDroneController.albumData.albumLoading = true
        self.droneController.djiDroneData.device!.camera!.mediaManager?.delete(self.files, withCompletion: { failedFiles, error in
            if error != nil || failedFiles.count != 0 {
                self.albumDroneController.albumData.albumLoading = false
                completion(false, true, ("(\(failedFiles.count)) file(s) Were Not Removed", "\(error!.localizedDescription)"))
            } else {
                self.droneController.pushCommand(command: FetchDroneMedia())
                completion(true, false, nil)
            }
        })
    }
}
