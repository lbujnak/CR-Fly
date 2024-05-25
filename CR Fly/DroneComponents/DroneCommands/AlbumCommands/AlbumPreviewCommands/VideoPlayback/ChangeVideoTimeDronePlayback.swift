import DJISDK
import SwiftUI

/**
 `ChangeVideoTimeDronePlayback` is a command class that manages the functionality of adjusting the playback position of a video being played from a DJI drone's media storage. This class is designed to interact directly with the DJI SDK to control video playback on a connected drone's camera system.
 
 - This command is typically used in a video playback interface where users can seek to different positions within a video, such as dragging a playback slider to a new position.
 - It is particularly useful in applications that provide detailed video playback controls for reviewing footage captured by drones, enabling precise navigation through video content.
 */
public class ChangeVideoTimeDronePlayback: Command {
    /// Reference to an instance of `DJIDroneController` that facilitates communication and control of the DJI drone.
    private let droneController = CRFly.shared.droneController as! DJIDroneController
    
    /// Reference to an instance of `AlbumDroneController` that manages the drone's album data and media playback states.
    private let albumDroneController = CRFly.shared.albumDroneController
    
    /// A `DJIMediaFile` representing the specific video file to be played back on the drone.
    private let file: DJIMediaFile
    
    /// Initializes the command with a specific `DJIMediaFile` to manipulate its playback position.
    public init(file: DJIMediaFile) {
        self.file = file
    }
    
    /// Executes the playback command.
    public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        if self.droneController.djiDroneData.device == nil || self.droneController.djiDroneData.device!.camera == nil {
            completion(false, true, ("Error Changing Video Playback Time", "Connection to the drone was lost, or the camera could not be detected."))
        } else if self.albumDroneController.albumData.albumPreviewController == nil || !(self.albumDroneController.albumData.albumPreviewController is AlbumDronePreviewController) {
            completion(true, false, nil)
        } else {
            let albumPreviewController = self.albumDroneController.albumData.albumPreviewController! as! AlbumDronePreviewController
            if albumPreviewController.albumPreviewData.videoCurrentTime == albumPreviewController.albumPreviewData.videoTotalTime {
                albumPreviewController.albumPreviewData.videoCurrentTime = 0
            }
            
            // Move playback position
            self.droneController.djiDroneData.device!.camera!.mediaManager!.move(toPosition: Float(albumPreviewController.albumPreviewData.videoCurrentTime), withCompletion: { error in
                if error != nil {
                    completion(false, true, ("Error Changing Video Playback Time", "Video time could not be changed. Error: \(error!.localizedDescription)"))
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
                        let albumPreviewController = self.albumDroneController.albumData.albumPreviewController as? AlbumDronePreviewController
                        
                        // If is not playing, stop playback
                        if !(albumPreviewController?.albumPreviewData.isPlayingVideo ?? true) {
                            self.droneController.djiDroneData.device!.camera!.mediaManager!.pause(completion: { error in
                                if error != nil {
                                    completion(false, true, ("Error Changing Video Playback Time", "Video could not be paused. Error: \(error!.localizedDescription)"))
                                } else {
                                    albumPreviewController?.userUsingSlider = false
                                    completion(true, false, nil)
                                }
                            })
                        } else {
                            albumPreviewController?.userUsingSlider = false
                            completion(true, false, nil)
                        }
                    }
                }
            })
        }
    }
}
