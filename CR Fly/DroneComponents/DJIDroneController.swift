import DJISDK
import SwiftUI

/**
 `DJIDroneController` is a concrete implementation of the `AlbumPreviewController` protocol tailored to manage the DJI drone interactions including media management, command execution related to the drone, and handles connectivity status updates.
 
 - This controller is integral for apps that interact with DJI drones, managing all aspects of connectivity, media management, and command execution.
 - It is designed to work within a broader system that involves multiple controllers managing different aspects of a drone's operation, such as media previews and downloads.
 */
public class DJIDroneController: CommandQueueController, DroneController {
    /// Reference to the `ViewController` responsible for managing navigation, presentation of different views within the application and displaying errors.
    private let viewController: ViewController
    
    /// Reference to an instance of `SceneController` that manages broader scene-related operations.
    public let sceneController: SceneController
    
    /// Reference to an instance of `AlbumSavedController` that manages the overall album of saved media.
    public let albumSavedController: AlbumSavedController
    
    /// Reference to the observable data class `DroneData` containing drone's operational data.
    public let droneData = DroneData()
    
    /// Reference to the observable data class `DJIDroneData` containing DJI drone's operational data.
    public let djiDroneData = DJIDroneData()
    
    /// Ensures that the `calculateDownloadSpeed()` method is executed only once at a time, preventing multiple parallel executions of this function.
    public var speedCalcIdentifier: String = ""
    
    /// Initializes a `DJIDroneController` with a given ViewController. Sets up the drone connection with specific parameters and handles SDK registration.
    public init(viewController: ViewController, sceneController: SceneController, albumSavedController: AlbumSavedController) {
        self.viewController = viewController
        self.sceneController = sceneController
        self.albumSavedController = albumSavedController
        super.init(commandRetries: 3, commandRetryTimeout: 1000, viewController: viewController)
    }
    
    // MARK: DroneController Methods
    
    /// Resumes a previously paused download process, continuing data retrieval from the last checkpoint. This function is used to restart the download without losing progress, optimizing bandwidth and user time.
    public func enterFromBackground() {
        self.connectToProduct()
    }
    
    /// Prepares the application for transition to the background by saving state, pausing ongoing tasks, or securing sensitive information.
    public func leaveToBackground() {
        self.droneData.deviceConnected = false
        self.commandExecutionEnabled = false
    }
    
    /// Manages various actions related to media downloads within the application. This method unifies the control of download processes, allowing the user to resume, pause, or completely stop media downloads. This design simplifies the interface for handling download actions, making it easier to manage network resources and user interactions with ongoing downloads.
    public func manageDownload(action: MediaTransferAction) {
        switch action {
        case .resumeTransfer:
            self.pushCommand(command: StartDroneMediaDownload(files: []))
        case .pauseTransfer:
            self.pushCommand(command: StopDroneMediaDownload(pauseOnly: true))
        case .stopTransfer:
            self.pushCommand(command: StopDroneMediaDownload(pauseOnly: false))
        }
    }
    
    /// Handler for when uploads are canceled, listing affected files.
    public func uploadCanceledFor(fileNames: Set<String>) {
        if self.droneData.mediaDownloadState != nil {
            let foundFiles = self.droneData.mediaDownloadState!.tempDownload.compactMap { downloadFile in
                fileNames.contains(downloadFile.fileName) ? downloadFile : nil
            }
            
            if !foundFiles.isEmpty {
                self.pushCommand(command: StopDroneMediaDownload(pauseOnly: true, forcePaused: true, withSuccessCompletion: {
                    if self.droneData.mediaDownloadState!.currentDownloadFile != nil, foundFiles.contains(self.droneData.mediaDownloadState!.currentDownloadFile!) {
                        self.droneData.mediaDownloadState!.currentDownloadFile = nil
                        self.droneData.mediaDownloadState!.transferedBytes -= self.droneData.mediaDownloadState!.currentFileOffset
                        self.droneData.mediaDownloadState!.currentFileOffset = 0
                    }
                    
                    self.droneData.mediaDownloadState!.downloadSet.subtract(foundFiles)
                    self.droneData.mediaDownloadState!.totalMedia -= foundFiles.count
                    self.droneData.mediaDownloadState!.totalBytes -= foundFiles.reduce(UInt(0), { $0 + UInt($1.fileSizeInBytes) })
                    self.pushCommand(command: StartDroneMediaDownload())
                }))
            }
        }
    }
    
    /// Opens the First Person View (FPV) User Interface for the drone, allowing real-time video streaming from the drone's camera to the application's user interface. This method is typically called to enable users to view live footage directly from the drone, essential for navigating or monitoring remote areas.
    public func openFPVView() {
        self.pushCommand(command: ExitDroneAlbum(withCompletion: {
            self.viewController.displayView(type: .droneFPVView, addPreviousToHistory: true)
        }))
    }
    
    // MARK: Extension Methods
    
    /// Initiates the upload and download of media files specified in `files` to the reconstruction software.
    public func uploadFiles(files: Set<DJIMediaFile>) {
        let albumSavedData = self.albumSavedController.albumSavedData
        let mediaUploadState = self.sceneController.sceneData.mediaUploadState
        
        var savedFiles: Set<DocURL> = []
        var downloadStartFor: Set<DJIMediaFile> = []
        var waitDownload = self.sceneController.sceneData.mediaUploadState?.waitDownload ?? []
        
        if albumSavedData.savedMediaURL != nil {
            for file in files {
                let alreadyUploading = mediaUploadState?.uploadSet.contains(where: { $0.getFileNameWithout(prefix: "_tmp.") == file.fileName}) ?? false || mediaUploadState?.waitDownload.contains(where: { $0.fileName == file.fileName }) ?? false
                
                if !alreadyUploading, !self.sceneController.sceneData.openedProject.fileList.contains(file.fileName) {
                    if CRFly.shared.albumDroneController.isMediaSaved(file: file) {
                        savedFiles.insert(albumSavedData.savedMediaURL!.appendFile(fileName: file.fileName))
                    } else {
                        downloadStartFor.insert(file)
                    }
                }
            }
        }
        
        if !downloadStartFor.isEmpty {
            for file in downloadStartFor {
                waitDownload.insert(MediaUploadState.DownloadFileData(fileName: file.fileName, fileSize: UInt(file.fileSizeInBytes)))
            }
            
            self.pushCommand(command: StartDroneMediaDownload(files: downloadStartFor, tempDownload: true))
        }
        
        if !savedFiles.isEmpty || !waitDownload.isEmpty {
            self.sceneController.uploadMedia(files: savedFiles, waitDownload: waitDownload)
        }
    }
}

extension DJIDroneController {
    /// Registers the app with the DJI SDK to begin interaction with DJI products.
    public func registerWithSDK() {
        let appKey = Bundle.main.object(forInfoDictionaryKey: SDK_APP_KEY_INFO_PLIST_KEY) as? String
        guard appKey != nil, appKey!.isEmpty == false else {
            self.viewController.showSimpleAlert(title: "AppKey error", msg: Text("Please enter your app key in the info.plist"))
            return
        }
        DJISDKManager.registerApp(with: self)
    }
    
    /// Attempts to establish a connection to a DJI drone.
    public func connectToProduct() {
        if self.droneData.deviceConnected { return }
        DJISDKManager.stopConnectionToProduct()
        if !DJISDKManager.startConnectionToProduct() {
            self.viewController.showSimpleAlert(title: "Drone Connection Error", msg: Text("There was a problem starting the connection."))
        }
    }
    
    /// Handles actions to take when a drone is successfully connected.
    private func droneConnected() {
        self.djiDroneData.device = DJISDKManager.product()
        self.droneData.deviceConnected = true
        self.commandExecutionEnabled = true
        if self.droneData.mediaDownloadState != nil {
            self.pushCommand(command: StartDroneMediaDownload(files: []))
        }
        
        CRFly.shared.changeAlbumMode(albumMode: .drone)
        if self.viewController.getViewType() == .albumView {
            self.pushCommand(command: EnterDroneAlbum())
            if self.albumSavedController.albumData.albumPreviewController == nil {
                self.viewController.displayView(type: .albumView, addPreviousToHistory: false)
            }
        }
    }
    
    /// Manages cleanup and state updates when the drone is disconnected.
    private func droneDisconnected() {
        self.clearCommandQueue()
        if self.droneData.mediaDownloadState != nil {
            self.sceneController.downloadCanceledFor(fileNames: Set(self.droneData.mediaDownloadState!.downloadSet.compactMap({ $0.fileName })))
            self.droneData.mediaDownloadState = nil
        }
        self.droneData.deviceConnected = false
        self.commandExecutionEnabled = false
        self.droneData.playbackMode = false
        self.djiDroneData.device = nil
        
        CRFly.shared.albumDroneController.cleanAlbum()
        CRFly.shared.changeAlbumMode(albumMode: .saved)
        if self.viewController.getViewType() == .albumView {
            CRFly.shared.albumDroneController.albumData.albumPreviewController = nil
            self.viewController.displayView(type: .albumView, addPreviousToHistory: false)
        }
    }
}

extension DJIDroneController: DJISDKManagerDelegate {
    /// Called when the DJI SDK updates the database download progress, primarily used for logging progress in the console.
    public func didUpdateDatabaseDownloadProgress(_ progress: Progress) {
        print("SDK downloading db file \(progress.completedUnitCount / progress.totalUnitCount)")
    }
    
    /// Called when the DJI SDK registration process completes. It handles errors if registration fails and attempts to connect to the drone if successful.
    public func appRegisteredWithError(_ error: Error?) {
        if error != nil {
            self.viewController.showSimpleAlert(title: "SDK Registered with error", msg: Text(error!.localizedDescription))
            return
        }
        self.connectToProduct()
    }
    
    /// Called when a DJI component (such as a camera or gimbal) connects to the mobile device. If not already connected, it triggers the drone connection process.
    public func componentConnected(withKey _: String?, andIndex _: Int) {
        if !self.droneData.deviceConnected, DJISDKManager.product() != nil, DJISDKManager.product()!.model != "Only RemoteController" {
            self.droneConnected()
        }
    }
    
    /// Called when a DJI component disconnects. It checks if the main product is still connected; if not, it performs cleanup operations.
    public func componentDisconnected(withKey _: String?, andIndex _: Int) {
        if self.droneData.deviceConnected, DJISDKManager.product() == nil || DJISDKManager.product()!.model == "Only RemoteController" {
            self.droneDisconnected()
        }
    }
}

extension DJIDroneController: DJIMediaManagerDelegate {
    /// Called whenever there is an update to the media playback state from the DJI drone's media manager.
    public func manager(_: DJIMediaManager, didUpdate state: DJIMediaVideoPlaybackState) {
        if !state.playingMedia.valid {
            self.pushCommandOnce(command: StopDroneVideoPlayback())
        }
        
        if CRFly.shared.albumDroneController.albumData.albumPreviewController != nil {
            if CRFly.shared.albumDroneController.albumData.albumPreviewController! is AlbumDronePreviewController {
                let albumPreviewController = CRFly.shared.albumDroneController.albumData.albumPreviewController as! AlbumDronePreviewController
                
                if !albumPreviewController.userUsingSlider, albumPreviewController.albumPreviewData.isPlayingVideo {
                    // At the end of the video, playtimes is reset to 0. However, since this function is invoked every 200ms, we can deduce that if the change in playtime exceeds the range of 200ms < 500ms, it indicates the video has ended.
                    let didVideoEnded = abs(albumPreviewController.albumPreviewData.videoCurrentTime - Double(state.playingPosition)) > 0.5
                    
                    if didVideoEnded, state.playbackStatus == .stopped, state.playingPosition == 0 {
                        albumPreviewController.albumPreviewData.previewLoading = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                            self.pushCommand(command: StartDroneVideoPlayback(file: state.playingMedia))
                        }
                    }
                    albumPreviewController.albumPreviewData.videoCurrentTime = Double(state.playingPosition)
                }
            }
        }
    }
}
