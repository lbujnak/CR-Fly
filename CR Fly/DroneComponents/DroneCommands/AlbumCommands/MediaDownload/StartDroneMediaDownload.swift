import DJISDK
import SwiftUI

/**
 `StartDroneMediaDownload` is a command class that initiates the media download process from a DJI drone to the application. It handles the preparation and starting of media downloads based on the specified set of media files.
 
 - This command is used when a user or automated process decides to download media from the drone. It checks for media validity, updates download sets, and handles conditions where media might already be saved or needs special handling due to its temporary nature.
 */
public class StartDroneMediaDownload: Command {
    /// Reference to the `ViewController` responsible for managing navigation, presentation of different views within the application and displaying errors.
    private let viewController = CRFly.shared.viewController
    
    /// Reference to an instance of `DJIDroneController` that facilitates communication and control of the DJI drone.
    private let droneController = CRFly.shared.droneController as! DJIDroneController
    
    /// Reference to an instance of `AlbumDroneController` that manages the drone's album data and media playback states.
    private let albumDroneController = CRFly.shared.albumDroneController
    
    /// Reference to an instance of `AlbumSavedController` that manages the overall album of saved media.
    private let albumSavedController = CRFly.shared.albumSavedController
    
    /// Reference to an instance of `SceneController` that manages broader scene-related operations.
    private let sceneController = CRFly.shared.sceneController
    
    /// A set of `DJIMediaFile` objects representing the media files to be downloaded.
    private var files: Set<DJIMediaFile>
    
    /// A Boolean flag indicating whether the download is temporary. Temporary downloads may be treated differently, such as not storing them permanently or not updating certain UI components.
    private let tempDownload: Bool
    
    /// Initializes the command with the specified files and download preference.
    public init(files: Set<DJIMediaFile> = [], tempDownload: Bool = false) {
        self.files = files
        self.tempDownload = tempDownload
    }
    
    /// Executes the download command, setting up and potentially starting the media download process.
    public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        let downloadingSet = self.droneController.droneData.mediaDownloadState?.downloadSet ?? []
        
        var newTotalBytes = self.droneController.droneData.mediaDownloadState?.totalBytes ?? 0
        var newTotalMedia = self.droneController.droneData.mediaDownloadState?.totalMedia ?? 0
        var newTempDownload = self.droneController.droneData.mediaDownloadState?.tempDownload ?? []
        var newDownloadSet = self.files.union(downloadingSet)
        
        // Check and remove files from newDownloadSet, that are invalid or already saved.
        // - If file is being uploaded and download is not marked as temporary, file will be added to album (as it was downloaded one).
        for file in self.files.union(downloadingSet) {
            if !file.valid || self.albumDroneController.isMediaSaved(file: file) {
                newDownloadSet.remove(file)
                newTempDownload.remove(file)
            } else {
                let uploadSetFile = self.sceneController.sceneData.mediaUploadState?.uploadSet.first(where: { $0.getFileNameWithout(prefix: "_tmp.") == file.fileName })
                
                if self.droneController.droneData.mediaDownloadState?.tempDownload.contains(file) ?? false {
                    self.droneController.droneData.mediaDownloadState!.tempDownload.remove(file)
                } else if uploadSetFile != nil {
                    if !self.tempDownload {
                        let copyUrl = DocURL(dirURL: uploadSetFile!.getDirectoryURL(), fileName: file.fileName)
                        if (try? uploadSetFile!.copyItem(to: copyUrl)) != nil {
                            self.albumSavedController.addToAlbum(file: copyUrl)
                        }
                    }
                    newDownloadSet.remove(file)
                    newTempDownload.remove(file)
                }
            }
        }
        
        // Calculate newTotalBytes and newTotalMedia, adding size and count of new files in download progress.
        for file in self.files.intersection(newDownloadSet.subtracting(downloadingSet)) {
            newTotalBytes += UInt(file.fileSizeInBytes)
            newTotalMedia += 1
        }
        
        // If download of any file is already in progress and marked as temporary, this mark will be removed.
        newTempDownload = self.tempDownload ? newTempDownload.union(self.files.subtracting(downloadingSet)) : newTempDownload.subtracting(self.files)
        
        // Notify, recalculate statistics and cancel of possible upgoing upload of invalid files found in download.
        let checkRemoved = downloadingSet.subtracting(newDownloadSet)
        if checkRemoved.count != 0 {
            
            newTotalBytes = self.droneController.droneData.mediaDownloadState?.transferedBytes ?? 0
            newTotalMedia -= checkRemoved.count
            for file in newDownloadSet {
                newTotalBytes += UInt(file.fileSizeInBytes)
            }
            
            self.sceneController.downloadCanceledFor(fileNames: Set(self.files.union(downloadingSet).subtracting(newDownloadSet).compactMap({ $0.fileName })))
            
            self.viewController.showSimpleAlert(title: "Error Downloading Media", msg: Text("Invalid files or files that have already been saved were detected. The download will proceed without these (\(checkRemoved.count))files."))
        }
        
        // Initializes/uptades the MediaDownloadState
        if self.droneController.droneData.mediaDownloadState != nil {
            if self.droneController.droneData.mediaDownloadState!.currentDownloadFile != nil, !newDownloadSet.contains(self.droneController.droneData.mediaDownloadState!.currentDownloadFile!) {
                self.droneController.droneData.mediaDownloadState!.currentDownloadFile = nil
                self.droneController.droneData.mediaDownloadState!.transferedBytes -= self.droneController.droneData.mediaDownloadState!.currentFileOffset
                self.droneController.droneData.mediaDownloadState!.currentFileOffset = 0
            }
            
            self.droneController.droneData.mediaDownloadState!.downloadSet = newDownloadSet
            self.droneController.droneData.mediaDownloadState!.tempDownload = newTempDownload
            self.droneController.droneData.mediaDownloadState!.totalBytes = newTotalBytes
            self.droneController.droneData.mediaDownloadState!.totalMedia = newTotalMedia
            
            if self.droneController.droneData.mediaDownloadState!.transferPaused {
                self.startDownload()
            }
        } else {
            if !newDownloadSet.isEmpty {
                self.droneController.droneData.mediaDownloadState = MediaDownloadState(downloadSet: newDownloadSet, tempDownload: newTempDownload, totalMedia: newTotalMedia, totalBytes: newTotalBytes)
                self.startDownload()
            }
        }
        completion(true, false, nil)
    }
    
    /// Initiates the actual download process if conditions are met (e.g., not currently fetching previews).
    private func startDownload() {
        self.droneController.pushCommand(command: DownloadDroneMedia())
        self.droneController.droneData.mediaDownloadState!.transferPaused = false
        self.droneController.droneData.mediaDownloadState!.transferForcePaused = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(5)) {
            self.droneController.startUpdatingDownloadSpeed()
        }
    }
}
