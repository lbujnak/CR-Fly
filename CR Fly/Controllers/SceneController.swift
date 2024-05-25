import SwiftUI

/// `SceneController` orchestrates the management and interaction of scene-related data and operations within an application. It extends `CommandQueueController` to leverage command queuing mechanisms, ensuring operations are performed sequentially and safely in a multi-threaded environment.
public protocol SceneController: CommandQueueController {
    /// Provides read-only access to the data pertinent to the current scene in the reconstruction software.
    var sceneData: SceneData { get }
    
    /// Provides read-only access to the data models associated with the scene, such as `PointCloud` and various 3D models, enabling operations on these models.
    var sceneModelData: SceneModelData { get }
    
    /// Ensures that the `calculateUploadSpeed()` method is executed only once at a time, preventing multiple parallel executions of this function.
    var speedCalcIdentifier: String { get set }
    
    /// Executes necessary actions when the application transitions from background to foreground, such as reinitializing resources or updating the UI.
    func enterFromBackground()
    
    /// Prepares the application for transition to the background by saving state, pausing ongoing tasks, or securing sensitive information.
    func leaveToBackground()
    
    /// Terminates all active connections and stops all ongoing communication with the reconstruction software.
    func disconnectScene()
    
    ///  Manages various actions related to projects within the reconstruction software. This method consolidates multiple project-related actions into a single function call. It allows for refreshing, changing, saving, closing, and deleting projects based on the specified action.
    func manageProject(action: SceneProjectAction)
    
    /// Generates a custom view providing a structured presentation of detailed project information, tailored to the user's specifications.
    func customProjectInfo(project: SceneProjectInfo) -> any View
    
    /// Loads saved models stored in device storage to the loaded project.
    func loadSavedModels()
    
    /// Requests a refresh or reconstruction of a model specified by `modelType`, updating or recreating its data.
    func refreshModel(modelType: SceneModelData.SceneModelType)
    
    /// Initiates the upload of media files specified in `files` and unsaved files in `waitDownload` to the reconstruction software.
    func uploadMedia(files: Set<DocURL>, waitDownload: Set<MediaUploadState.DownloadFileData>)
    
    /// Manages various actions related to media upload within the application. This method unifies the control of upload processes, allowing the user to resume, pause, or completely stop media uploads. This design simplifies the interface for handling upload actions, making it easier to manage network resources and user interactions with ongoing uploads.
    func manageUpload(action: MediaTransferAction)
    
    /// Handler used to respond canceled downloads, listing affected files.
    func downloadCanceledFor(fileNames: Set<String>)
    
    /// Prepares the specified file for uploading, potentially marking it as a temporary download.
    func readyToUpload(fileURL: DocURL, fileName: String)
}

public extension SceneController {
    /// Initiates the process of dynamically updating the upload speed. This method sets the run identifier and begins the speed calculation process.
    func startUpdatingUploadSpeed() {
        let runIdentifier = UUID().uuidString
        self.speedCalcIdentifier = runIdentifier
        self.calculateUploadSpeed(runIdentifier: runIdentifier)
    }
            
    /// Dynamically updates the upload speed based on the amount of data uploaded since the last calculation. This method checks if the upload is active and not paused, calculates the new speed in Bps, and schedules itself to run again in 500 milliseconds. This ensures continuous monitoring and updating of the upload speed during the media upload process.
    private func calculateUploadSpeed(runIdentifier: String) {
        if(self.speedCalcIdentifier == runIdentifier) {
            if self.sceneData.mediaUploadState != nil, !self.sceneData.mediaUploadState!.transferPaused {
                let downloaded = self.sceneData.mediaUploadState!.transferedBytes
                
                if self.sceneData.mediaUploadState!.speedCalcLastBytes > downloaded {
                    self.sceneData.mediaUploadState!.speedCalcLastBytes = downloaded
                }
                
                let realByteCnt: UInt! = downloaded - self.sceneData.mediaUploadState!.speedCalcLastBytes
                let newSpeed = Double(realByteCnt) * 2
                
                self.sceneData.mediaUploadState!.transferSpeed = newSpeed
                self.sceneData.mediaUploadState!.speedCalcLastBytes = downloaded
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                    self.calculateUploadSpeed(runIdentifier: runIdentifier)
                }
            }
        }
    }
}
