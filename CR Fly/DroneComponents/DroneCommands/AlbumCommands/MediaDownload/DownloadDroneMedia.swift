import DJISDK
import SwiftUI

/**
 `DownloadDroneMedia` is a command class responsible for downloading media files from DJI drones. It manages the downloading process, ensuring files are fetched and stored correctly while handling any issues that may arise during the operation.
 
 - The class is utilized within an app to initiate and manage the download of media files from a drone to the local storage, providing detailed management of the file transfer process.
 - It ensures that the download respects the system's current state, including whether downloads should be paused or stopped based on various conditions.
 
 - Note: The class extensively manages file states, checking for errors, and ensuring that file transfers are completed without corruption. Proper error handling within the class allows for responsive and user-friendly media management in applications involving drone interactions.
 */
public class DownloadDroneMedia: Command {
    /// Reference to the `ViewController` responsible for managing navigation, presentation of different views within the application and displaying errors.
    private let viewController = CRFly.shared.viewController
    
    /// Reference to an instance of `DJIDroneController` that facilitates communication and control of the DJI drone.
    private let droneController = CRFly.shared.droneController as! DJIDroneController
    
    /// Reference to an instance of `AlbumSavedController` that manages the overall album of saved media.
    private let albumSavedController = CRFly.shared.albumSavedController
    
    /// Reference to an instance of `SceneController` that manages broader scene-related operations.
    private let sceneController = CRFly.shared.sceneController
    
    /// A boolean that indicates whether a stop command has been issued during the download process, ensuring the download does not proceed further erroneously.
    private var stopCommandExecuted: Bool = false
    
    /// Begins the download process of media files. If there's no media download state or if it's paused, the method exits early. It checks if media exists to be downloaded and handles directory availability for saving files.
    public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        if self.droneController.droneData.mediaDownloadState?.transferPaused ?? true {
            completion(true, false, nil)
        } else if self.droneController.droneData.mediaDownloadState!.downloadSet.isEmpty {
            self.droneController.droneData.mediaDownloadState = nil
        } else if self.albumSavedController.albumSavedData.savedMediaURL == nil {
            completion(false, false, ("Error Downloading Media", "Failed to fetch load directory for saved files."))
        } else {
            
            // Check success of last download, if it was unsuccessful, download will continue from last saved byte.
            if self.droneController.droneData.mediaDownloadState!.currentDownloadFile == nil {
                self.droneController.droneData.mediaDownloadState!.currentDownloadFile = self.droneController.droneData.mediaDownloadState!.downloadSet.first!
                self.droneController.droneData.mediaDownloadState!.currentFileOffset = 0
            }
            
            let file = self.droneController.droneData.mediaDownloadState!.currentDownloadFile!
            let fileUrl = self.albumSavedController.albumSavedData.savedMediaURL!.appendFile(fileName: "_tmp." + file.fileName)
            
            var fileHandle: FileHandle!
            
            // Creates file and opens its fileHandle for writing.
            // - If file already existed and download does not detect resume for this file, it will be removed.
            do {
                if fileUrl.existsItem(), self.droneController.droneData.mediaDownloadState!.currentFileOffset == 0 {
                    try fileUrl.removeItem()
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd kk:mm:ss"
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                
                let attributes: [FileAttributeKey: Date] = [.creationDate: dateFormatter.date(from: String(file.timeCreated))!]
                
                try fileUrl.createItem()
                try fileUrl.setAttributesOfItem(attributes: attributes)
                
                fileHandle = try FileHandle(forWritingTo: fileUrl.getURL())
                try fileHandle!.seekToEnd()
            } catch {
                self.droneController.droneData.mediaDownloadState?.transferPaused = true
                completion(false, true, ("Error Downloading Media", "Failed to prepare temporary file in device storage. Pausing download and removing current file from download list. Error: \(error.localizedDescription)"))
            }
            
            // Starts download of media
            file.fetchData(withOffset: self.droneController.droneData.mediaDownloadState?.currentFileOffset ?? 0, update: DispatchQueue.main) { data, done, error in
                
                if self.droneController.droneData.mediaDownloadState == nil || self.droneController.droneData.mediaDownloadState!.transferPaused {
                    return
                }
                
                // If error was detected while download is not paused, it will be force paused.
                if error != nil, !self.droneController.droneData.mediaDownloadState!.transferPaused {
                    if !self.stopCommandExecuted {
                        self.viewController.showSimpleAlert(title: "Error Downloading Media", msg: Text("\(error!.localizedDescription). Download will be automaticlly paused."))
                        file.stopFetchingFileData()
                        self.droneController.droneData.mediaDownloadState!.transferPaused = true
                        self.stopCommandExecuted = true
                        return
                    }
                }
                
                fileHandle.write(data!)
                self.droneController.droneData.mediaDownloadState!.transferedBytes += UInt(data!.count)
                self.droneController.droneData.mediaDownloadState!.currentFileOffset += UInt(data!.count)
                
                // Action when download is marked as finished.
                if done {
                    let isTempFile = self.droneController.droneData.mediaDownloadState!.tempDownload.contains(file)
                    let finalUrl = self.albumSavedController.albumSavedData.savedMediaURL!.appendFile(fileName: file.fileName)
                    
                    do {
                        try fileHandle.close()
                        
                        if(!isTempFile) {
                            try fileUrl.moveItem(to: finalUrl, withIntermediateDirectories: true)
                            self.albumSavedController.addToAlbum(file: finalUrl)
                        }
                    } catch {
                        self.droneController.droneData.mediaDownloadState!.transferPaused = true
                        self.viewController.showSimpleAlert(title: "Error Downloading Media", msg: Text("The file handler could not be closed, or the file renaming operation was unsuccessful."))
                        return
                    }
                    
                    // Updates MediaDownloadState and starts download of new file
                    DispatchQueue.main.async {
                        self.droneController.droneData.mediaDownloadState!.transferedMedia += 1
                        self.droneController.droneData.mediaDownloadState!.downloadSet.remove(file)
                        self.droneController.droneData.mediaDownloadState!.tempDownload.remove(file)
                        self.droneController.droneData.mediaDownloadState!.currentDownloadFile = nil
                        self.droneController.pushCommand(command: DownloadDroneMedia())
                        
                        if self.sceneController.sceneData.mediaUploadState?.waitDownload.count ?? 0 != 0 {
                            self.sceneController.readyToUpload(fileURL: isTempFile ? fileUrl : finalUrl, fileName: file.fileName)
                        }
                    }
                }
            }
        }
        completion(true, false, nil)
    }
}
