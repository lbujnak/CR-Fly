import DJISDK
import SwiftUI

/**
 `StopDroneVideoPlayback` is a command class designed to control the playback of video files from a DJI drone. It interacts with the drone's media management system to stop video playback and manages the state associated with this playback within the application.
 
 - This command is used when a user wishes to stop a currently playing video file on the drone. It checks for device connectivity and attempts to stop the playback, handling any errors and updating the application state accordingly.
 - Critical errors and operational failures are communicated back to the caller through a detailed error message, facilitating debugging and user feedback.
 
 This class leverages functionality from the DJI SDK to interact with the drone's hardware and manage media files effectively, integrating these capabilities into a cohesive application workflow.
 */
public class StopDroneVideoPlayback: Command {
    /// Reference to an instance of `DJIDroneController` that facilitates communication and control of the DJI drone.
    private let droneController = CRFly.shared.droneController as! DJIDroneController
    
    /// Executes the playback command.
    public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        if self.droneController.djiDroneData.device == nil || self.droneController.djiDroneData.device!.camera == nil {
            completion(false, true, ("Error Stopping Video Playback", "Connection to the drone was lost, or the camera could not be detected."))
        } else {
            self.droneController.djiDroneData.device!.camera!.mediaManager!.stop(completion: { error in
                if error != nil {
                    completion(false, true, ("Error Stopping Video Playback", "Video could not be stopped. Error: \(error!.localizedDescription)"))
                } else {
                    completion(true, false, nil)
                }
            })
        }
    }
}
