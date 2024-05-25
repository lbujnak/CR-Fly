import DJISDK
import SwiftUI

/**
 `StartDroneVideoPlayback` is a command class designed to control the playback of video files from a DJI drone. It interacts with the drone's media management system to start video playback and manages the state associated with this playback within the application.
 
 - This command is typically used when a user selects a video file from the drone's storage through the application's UI. The class handles checking device connectivity, initiating playback, and updating relevant UI components based on the playback state.
 - Errors during playback (like connectivity issues or file-specific problems) are handled gracefully, providing detailed feedback to the user.
 
 This class leverages functionality from the DJI SDK to interact with the drone's hardware and manage media files effectively, integrating these capabilities into a cohesive application workflow.
 */
public class StartDroneVideoPlayback: Command {
    /// Reference to an instance of `DJIDroneController` that facilitates communication and control of the DJI drone.
    private let droneController = CRFly.shared.droneController as! DJIDroneController
    
    /// Reference to an instance of `AlbumDroneController` that manages the drone's album data and media playback states.
    private let albumDroneController = CRFly.shared.albumDroneController
    
    /// A `DJIMediaFile` representing the specific video file to be played back on the drone.
    private let file: DJIMediaFile
    
    /// Initializes the command with a specific DJI media file intended for playback.
    public init(file: DJIMediaFile) {
        self.file = file
    }
    
    /// Executes the playback command.
    public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        if self.droneController.djiDroneData.device == nil || self.droneController.djiDroneData.device!.camera == nil {
            completion(false, true, ("Error Starting Video Playback", "Connection to the drone was lost, or the camera could not be detected."))
        } else {
            self.droneController.djiDroneData.device!.camera!.mediaManager!.playVideo(self.file, withCompletion: { error in
                if error != nil {
                    completion(false, true, ("Error Starting Video Playback", "Video could not be played. Error: \(error!.localizedDescription)"))
                } else {
                    if self.albumDroneController.albumData.albumPreviewController == nil {
                        self.droneController.djiDroneData.device!.camera!.mediaManager!.stop()
                    } else {
                        self.albumDroneController.albumData.albumPreviewController!.albumPreviewData.videoCurrentTime = 0
                        self.albumDroneController.albumData.albumPreviewController!.albumPreviewData.videoTotalTime = Double(self.file.durationInSeconds)
                        self.albumDroneController.albumData.albumPreviewController!.albumPreviewData.previewLoading = false
                        self.albumDroneController.albumData.albumPreviewController!.albumPreviewData.isPlayingVideo = true
                    }
                    completion(true, false, nil)
                }
            })
        }
    }
}
