import SwiftUI

/**
 `StartMediaUpload` is a command class responsible for initializing the process of uploading media files from the local storage to a remote server or cloud storage. It handles various conditions and settings to ensure that media files are properly managed during the upload process.
 */
public class StartMediaUpload: Command {
    /// Reference to the `ViewController` responsible for managing navigation, presentation of different views within the application and displaying errors.
    private let viewController = CRFly.shared.viewController
    
    /// Reference to an instance of `SceneController` that manages broader scene-related operations.
    private let sceneController = CRFly.shared.sceneController as! RCNodeController
    
    /// Reference to an instance of `DJIDroneController` that facilitates communication and control of the DJI drone.
    private let droneController = CRFly.shared.droneController
    
    /// Reference to an instance of `AlbumSavedController` that manages the overall album of saved media.
    private let albumSavedController = CRFly.shared.albumSavedController
    
    /// A set of file `DocURL`s that represent the media files to be uploaded.
    private var savedFiles: Set<DocURL>
    
    /// Array of pairs containing file name and size that need to be downloaded before they can be uploaded, indicating dependencies within the upload process.
    public var waitDownload: Set<MediaUploadState.DownloadFileData>
    
    /// A boolean flag that determines whether the upload should automatically restart if it was paused by the user.
    private var startIfUserPaused: Bool
    
    /// Initializes the command with the specified parameters for handling the files during the upload process.
    public init(savedFiles: Set<DocURL> = [], waitDownload: Set<MediaUploadState.DownloadFileData> = [], startIfUserPaused: Bool = true) {
        self.savedFiles = savedFiles
        self.waitDownload = waitDownload
        self.startIfUserPaused = startIfUserPaused
    }
    
    /// Overrides the base execute method to initialize the upload process, handling conditions for new uploads or resuming paused ones. This method orchestrates the preparation and commencement of the media upload based on the current application state and the properties defined during initialization.
    public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        let uploadingSet = self.sceneController.sceneData.mediaUploadState?.uploadSet ?? []
        let downloadingSet = self.sceneController.sceneData.mediaUploadState?.waitDownload ?? []
        
        var newTotalBytes = self.sceneController.sceneData.mediaUploadState?.totalBytes ?? 0
        var newTotalMedia = self.sceneController.sceneData.mediaUploadState?.totalMedia ?? 0
        var newUploadSet = self.savedFiles.union(uploadingSet)
        var newWaitDownloadSet = self.waitDownload.union(downloadingSet)
        
        // Removes attempt for duplication of same file with 2 different storage locations - when file is
        // in savedFiles, it is already saved -> we can afford it
        for file in self.savedFiles {
            if newUploadSet.contains(where: { $0.getFileNameWithout(prefix: "_tmp.") == file.getFileNameWithout(prefix: "_tmp.") && $0.getFileName() != file.getFileName() }) {
                newUploadSet.remove(file)
            }
        }
        
        // Check and remove files from newUploadSet, that not saved or already in project.
        for file in self.savedFiles.union(uploadingSet) {
            if !file.existsItem() || self.sceneController.sceneData.openedProject.fileList.contains(file.getFileNameWithout(prefix: "_tmp.")) {
                newUploadSet.remove(file)
            }
        }
        
        // Check and remove files from newWaitDownload, that are in savedFiles or already in project.
        for file in self.waitDownload.union(downloadingSet) {
            if self.sceneController.sceneData.openedProject.fileList.contains(file.fileName) || newUploadSet.contains(where: { $0.getFileNameWithout(prefix: "_tmp.") == file.fileName}){
                newWaitDownloadSet.remove(file)
            }
        }
        
        // Calculate file size and count for new savedFiles in upload.
        for file in self.savedFiles.intersection(newUploadSet.subtracting(uploadingSet)) {
            do {
                guard let fileSize = try file.getAttributesOfItem()[.size] as? Int else {
                    completion(false, false, ("Error Starting Media Upload", "The file size of the saved file \(file.getFileName()) could not be determined."))
                    return
                }
                
                newTotalBytes += UInt(fileSize)
                newTotalMedia += 1
            } catch {
                completion(false, false, ("Error Starting Media Upload", "The file attributes needed to read the saved file could not be fetched."))
                return
            }
        }

        // Calculate totalBytes and totalMedia for waitDownload files in upload.
        for file in self.waitDownload.intersection(newWaitDownloadSet.subtracting(downloadingSet)) {
            newTotalBytes += file.fileSize
            newTotalMedia += 1
        }
        
        // Notify, recalculate statistics and cancel of possible upgoing upload of invalid files found in download.
        let checkSaved = uploadingSet.subtracting(newUploadSet)
        let checkDownload = downloadingSet.subtracting(newWaitDownloadSet)
        
        if checkSaved.count != 0 || checkDownload.count != 0 {
            newTotalBytes = self.sceneController.sceneData.mediaUploadState?.transferedBytes ?? 0
            newTotalMedia -= checkSaved.count
            newTotalMedia -= checkDownload.count
            
            for file in newWaitDownloadSet {
                newTotalBytes += UInt(file.fileSize)
            }
            
            for file in newUploadSet {
                do {
                    guard let fileSize = try file.getAttributesOfItem()[.size] as? Int else {
                        completion(false, false, ("Error Starting Media Upload", "The file size of the saved file \(file.getFileName()) could not be determined."))
                        return
                    }
                    
                    newTotalBytes += UInt(fileSize)
                } catch {
                    completion(false, false, ("Error Starting Media Upload", "The file attributes needed to read the saved file could not be fetched."))
                    return
                }
            }
            
            if checkDownload.count != 0 {
                self.droneController.uploadCanceledFor(fileNames: Set(checkDownload.compactMap({ $0.fileName })))
            }
 
            if checkSaved.count != 0 {
                self.viewController.showSimpleAlert(title: "Error Uploading Media", msg: Text("Files that are not saved in device were detected. The upload will proceed without these (\(checkSaved.count + checkDownload.count))files."))
            }
        }
        
        // Initialize MediaUploadState
        if self.sceneController.sceneData.mediaUploadState == nil {
            if !newUploadSet.isEmpty || !newWaitDownloadSet.isEmpty {
                self.sceneController.sceneData.mediaUploadState = MediaUploadState(uploadSet: newUploadSet, waitDownload: newWaitDownloadSet, totalMedia: newTotalMedia, totalBytes: newTotalBytes)
            }
        } else {
            if newUploadSet.isEmpty, newWaitDownloadSet.isEmpty {
                self.sceneController.sceneData.mediaUploadState = nil
            }
            else {
                self.sceneController.sceneData.mediaUploadState!.uploadSet = newUploadSet
                self.sceneController.sceneData.mediaUploadState!.waitDownload = newWaitDownloadSet
                self.sceneController.sceneData.mediaUploadState!.totalBytes = newTotalBytes
                self.sceneController.sceneData.mediaUploadState!.totalMedia = newTotalMedia
                
                if self.sceneController.sceneData.mediaUploadState!.transferPaused {
                    self.sceneController.sceneData.mediaUploadState!.speedCalcLastBytes = self.sceneController.sceneData.mediaUploadState!.transferedBytes
                }
            }
        }
        
        // Start the upload process
        if !newUploadSet.isEmpty, (self.startIfUserPaused || self.sceneController.sceneData.mediaUploadState!.transferForcePaused) {
            self.startUpload()
        }
        completion(true, false, nil)
    }
    
    /// Begins the media upload process directly. This method is called from within `execute()` when all conditions are satisfied to start or resume uploading.
    private func startUpload() {
        self.sceneController.pushCommand(command: UploadMedia())
        self.sceneController.sceneData.mediaUploadState!.transferPaused = false
        self.sceneController.sceneData.mediaUploadState!.transferForcePaused = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            self.sceneController.startUpdatingUploadSpeed()
        }
    }
}
