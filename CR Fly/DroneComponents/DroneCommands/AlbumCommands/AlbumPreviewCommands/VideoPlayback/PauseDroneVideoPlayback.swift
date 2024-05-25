import DJISDK
import SwiftUI

/**
 `PauseDroneVideoPlayback` is a command class designed to control the playback of video files from a DJI drone. It interacts with the drone's media management system to pause video playback and manages the state associated with this playback within the application.
 
 - This command is triggered when a user wishes to pause a currently playing video file on the drone. The method checks for device connectivity, the presence of a necessary media controller, and attempts to pause the playback, handling any errors and updating the application state accordingly.
 - It is especially useful in scenarios where users need to temporarily halt video playback to focus on other tasks or due to external interruptions.
 
 This class leverages functionality from the DJI SDK to interact with the drone's hardware and manage media files effectively, integrating these capabilities into a cohesive application workflow.
 */
public class PauseDroneVideoPlayback: Command {
    /// Reference to an instance of `DJIDroneController` that facilitates communication and control of the DJI drone.
    private let droneController = CRFly.shared.droneController as! DJIDroneController
    
    /// Reference to an instance of `AlbumDroneController` that manages the drone's album data and media playback states.
    private let albumDroneController = CRFly.shared.albumDroneController
    
    /// Executes the playback command.
    public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        if self.droneController.djiDroneData.device == nil || self.droneController.djiDroneData.device!.camera == nil {
            completion(false, true, ("Error Pausing Video Playback", "Connection to the drone was lost, or the camera could not be detected."))
        } else if self.albumDroneController.albumData.albumPreviewController == nil || !(self.albumDroneController.albumData.albumPreviewController is AlbumDronePreviewController) {
            completion(true, false, nil)
        } else {
            self.droneController.djiDroneData.device!.camera!.mediaManager!.pause(completion: { error in
                if error != nil {
                    completion(false, true, ("Error Pausing Video Playback", "Video could not be paused. Error: \(error!.localizedDescription)"))
                } else {
                    self.albumDroneController.albumData.albumPreviewController?.albumPreviewData.isPlayingVideo = false
                    completion(true, false, nil)
                }
            })
        }
    }
}
