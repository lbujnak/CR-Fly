import DJISDK
import SwiftUI

/**
 `ExitDroneAlbum` is a command class within the CRFly application framework that manages the transition of a DJI drone's camera from media playback or download mode back to a state suitable for live video feed reception. This transition is critical for operations requiring real-time video streaming, such as live monitoring or active piloting.
 
 The class encapsulates commands sent to the drone's camera using the DJI SDK, ensuring that the camera exits from modes that prevent live video streaming. It integrates with the broader application workflow by coordinating with UI and hardware control components to provide a seamless user experience.
 
 - Note: The command interacts directly with the drone's hardware via the DJI SDK, handling various states of the camera and providing appropriate feedback to the user through completion handlers.
 
 - Warning: This command should be used carefully, as improper use may disrupt ongoing media downloads or playback operations on the drone.
 */
public class ExitDroneAlbum: Command {
    /// Reference to an instance of `DJIDroneController` that facilitates communication and control of the DJI drone.
    private let droneController = CRFly.shared.droneController as! DJIDroneController
    
    /// A closure executed after the album mode is successfuly exited.
    private let completionBlock: () -> Void
    
    /// Initializes a new instance with options to add a completion handler.
    public init(withCompletion: @escaping () -> Void = {}) {
        self.completionBlock = withCompletion
    }
    
    /// Executes the command to initiate the exit  from the drone's photo album mode.
    public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        if self.droneController.djiDroneData.device == nil || self.droneController.djiDroneData.device!.camera == nil {
            completion(false, true, ("Error Opening Photo Album", "Connection to the drone was lost, or the camera could not be detected."))
        } else {
            let camera = self.droneController.djiDroneData.device!.camera!
            
            if camera.displayName == DJICameraDisplayNameZenmuseP1 ||
                camera.displayName == DJICameraDisplayNameMavicAir2Camera {
                camera.exitPlayback(completion: { error in
                    self.evaulateResult(error: error, completion: completion)
                })
            } else {
                camera.setMode(.broadcast, withCompletion: { error in
                    self.evaulateResult(error: error, completion: completion)
                })
            }
        }
    }
    
    /// Method used to handle the completion callback of camera mode change commands.
    private func evaulateResult(error: Error?, completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        if error != nil {
            completion(false, true, ("Error Closing Photo Album", error!.localizedDescription))
        } else {
            self.droneController.droneData.playbackMode = false
            self.completionBlock()
            completion(true, false, nil)
        }
    }
}
