import DJISDK
import SwiftUI

/**
 `StopDroneMediaDownload` is a command class used to stop or pause media download operations from DJI drones. This class plays a crucial role in managing media downloads, allowing for controlled interruption based on user actions or system conditions.
 
 - This class is utilized within the drone application to manage downloads from the drone's media storage. It ensures that downloads can be safely paused or stopped, preserving the integrity of both the download process and the downloaded media.
 
 - Note: The decision to pause or stop is determined by pauseOnly and forcePaused flags, which can be adjusted depending on the operational context or user preference. Proper error handling and cleanup are crucial to prevent resource leaks and ensure the integrity of the file system.
 */
public class StopDroneMediaDownload: Command {
    /// Reference to an instance of `DJIDroneController` that facilitates communication and control of the DJI drone.
    private let droneController = CRFly.shared.droneController as! DJIDroneController
    
    /// Reference to an instance of `AlbumSavedController` that manages the overall album of saved media.
    private let albumSavedController = CRFly.shared.albumSavedController
    
    /// Reference to an instance of `SceneController` that manages broader scene-related operations.
    private let sceneController = CRFly.shared.sceneController
    
    /// A boolean flag indicating whether the download should be paused (`true`) or completely stopped (`false`).
    private let pauseOnly: Bool
    
    /// A boolean flag indicating whether the pause is forced, typically used to address specific conditions or errors.
    private let forcePaused: Bool
    
    /// A closure executed after the download has been paused or stopped.
    private let successCompletionBlock: () -> Void
    
    /// Initializes a new instance with options to pause or stop the download and a completion handler, which is executed when download process is successfully paused/stopped.
    public init(pauseOnly: Bool, forcePaused: Bool = false, withSuccessCompletion: @escaping () -> Void = {}) {
        self.pauseOnly = pauseOnly
        self.forcePaused = forcePaused
        self.successCompletionBlock = withSuccessCompletion
    }
    
    /// Executes the stop or pause command. If the download is currently active, it will be either paused or stopped based on the properties set during initialization
    public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        if self.droneController.droneData.mediaDownloadState != nil {
            if self.droneController.droneData.mediaDownloadState!.downloadSet.isEmpty {
                self.droneController.droneData.mediaDownloadState = nil
                self.successCompletionBlock()
            } else {
                let file = self.droneController.droneData.mediaDownloadState!.downloadSet.first!
        
                file.stopFetchingFileData { _ in
                        if !self.pauseOnly {
                            if self.albumSavedController.albumSavedData.savedMediaURL != nil {
                                let fileUrl = self.albumSavedController.albumSavedData.savedMediaURL!.appendFile(fileName: "_tmp." + file.fileName)
                                try? fileUrl.removeItem()
                            }
                            
                            // Inform SceneController of canceled download.
                            if self.sceneController.sceneData.mediaUploadState?.waitDownload.count ?? 0 != 0 {
                                self.sceneController.downloadCanceledFor(fileNames: Set(self.droneController.droneData.mediaDownloadState!.downloadSet.compactMap({ $0.fileName })))
                            }
                            self.droneController.droneData.mediaDownloadState = nil
                        } else {
                            self.droneController.droneData.mediaDownloadState?.transferPaused = true
                            self.droneController.droneData.mediaDownloadState?.transferForcePaused = self.forcePaused
                        }
                        
                    DispatchQueue.main.async {
                        self.successCompletionBlock()
                    }
                    completion(true, false, nil)
                    return
                }
            }
        }
        completion(true, false, nil)
    }
}
