import DJISDK
import SwiftUI

/**
 `ResumeDroneVideoPlayback`is a command class designed to control the playback of video files from a DJI drone. It interacts with the drone's media management system to resume video playback and manages the state associated with this playback within the application.
 
 - This command is used when a user initiates the action to resume paused video playback on the drone. It ensures that the system checks for all necessary conditions (e.g., valid drone and camera connection) before attempting to resume playback.
 - Suitable for scenarios where video playback was previously paused, and the user wishes to continue viewing drone-captured footage.
 
 This class leverages functionality from the DJI SDK to interact with the drone's hardware and manage media files effectively, integrating these capabilities into a cohesive application workflow.
 */
public class ResumeDroneVideoPlayback: Command {
    /// Reference to an instance of `DJIDroneController` that facilitates communication and control of the DJI drone.
    private let droneController = CRFly.shared.droneController as! DJIDroneController
    
    /// Reference to an instance of `AlbumDroneController` that manages the drone's album data and media playback states.
    private let albumDroneController = CRFly.shared.albumDroneController
    
    /// Executes the playback command.
    public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        if self.droneController.djiDroneData.device == nil || self.droneController.djiDroneData.device!.camera == nil {
            completion(false, true, ("Error Resuming Video Playback", "Connection to the drone was lost, or the camera could not be detected."))
        } else if self.albumDroneController.albumData.albumPreviewController == nil || !(self.albumDroneController.albumData.albumPreviewController is AlbumDronePreviewController) {
            completion(true, false, nil)
        } else {
            self.droneController.djiDroneData.device!.camera!.mediaManager!.resume(completion: { error in
                if error != nil {
                    completion(false, true, ("Error Resuming Video Playback", "Video could not be resumed. Error: \(error!.localizedDescription)"))
                } else {
                    self.albumDroneController.albumData.albumPreviewController?.albumPreviewData.isPlayingVideo = true
                    completion(true, false, nil)
                }
            })
        }
    }
}
