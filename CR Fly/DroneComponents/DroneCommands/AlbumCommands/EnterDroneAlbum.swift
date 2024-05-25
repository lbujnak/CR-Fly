import DJISDK
import SwiftUI

/**
 `EnterDroneAlbum` is a command class that handles the process of entering the media playback or download mode on a DJI drone's camera. This class is crucial for transitioning the camera into a state where media files can be managed and retrieved.
 
 - This command is used when a user intends to review or manage the media stored on the drone, such as images and videos captured during flights.
 - It adjusts the camera's mode to either 'Playback' or 'Media Download' depending on the camera model and its current state, facilitating the retrieval of media files.
 
 This class leverages functionality from the DJI SDK to interact with the drone's hardware and manage media files effectively, integrating these capabilities into a cohesive application workflow.
 */
public class EnterDroneAlbum: Command {
    /// Reference to an instance of `DJIDroneController` that facilitates communication and control of the DJI drone.
    private let droneController = CRFly.shared.droneController as! DJIDroneController
    
    /// Executes the command to initiate the entry into the drone's photo album mode.
    public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        if self.droneController.djiDroneData.device == nil || self.droneController.djiDroneData.device!.camera == nil {
            completion(false, true, ("Error Opening Photo Album", "Connection to the drone was lost, or the camera could not be detected."))
        } else {
            let camera = self.droneController.djiDroneData.device!.camera!
            
            if self.droneController.droneData.playbackMode {
                self.droneController.pushCommand(command: FetchDroneMedia())
                completion(true, false, nil)
            } else {
                if camera.displayName == DJICameraDisplayNameZenmuseP1 ||
                    camera.displayName == DJICameraDisplayNameMavicAir2Camera {
                    camera.enterPlayback(completion: { error in
                        self.evaulateResult(error: error, completion: completion)
                    })
                } else {
                    camera.setMode(.mediaDownload, withCompletion: { error in
                        self.evaulateResult(error: error, completion: completion)
                    })
                }
            }
        }
    }
    
    /// Method used to handle the completion callback of camera mode change commands. It evaluates the result of attempting to switch the drone's camera to playback or media download mode and executes further actions based on the outcome.
    private func evaulateResult(error: Error?, completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        if error != nil {
            completion(false, true, ("Error Opening Photo Album", error!.localizedDescription))
        } else {
            self.droneController.droneData.playbackMode = true
            self.droneController.pushCommand(command: FetchDroneMedia())
            completion(true, false, nil)
        }
    }
}
