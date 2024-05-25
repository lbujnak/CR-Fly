import DJISDK
import SwiftUI

/**
 `AlbumDronePreviewController` is a concrete implementation of the `AlbumPreviewController` protocol tailored to manage the preview functionalities of media files within a drone's album. It is specifically designed to handle operations such as displaying previews, starting and stopping video playback, and managing file deletions and uploads for drone-related media.
 
 - This controller is used within a SwiftUI view environment where drone media files need to be managed and interacted with, particularly in scenarios involving complex media types like videos where playback control is necessary.
 */
public class AlbumDronePreviewController: AlbumPreviewController {
    /// Reference to the `ViewController` responsible for managing navigation, presentation of different views within the application and displaying errors.
    private let viewController = CRFly.shared.viewController
    
    /// Reference to an instance of `DJIDroneController` that facilitates communication and control of the DJI drone.
    private let droneController = CRFly.shared.droneController as! DJIDroneController
    
    /// Reference to an instance of `AlbumDroneController` that manages the overall album of drone's media.
    private let albumDroneController = CRFly.shared.albumDroneController
    
    /// Reference to the observable data class `DroneData` containing drone's operational data.
    private let droneData = CRFly.shared.droneController.droneData
    
    /// Reference to the observable data class `AlbumData`, encapsulating details such as album content, settings, etc.
    private let albumData = CRFly.shared.albumDroneController.albumData
    
    /// Reference to the observable data class `AlbumPreviewData`  that provides the necessary context and details for the previewed album.
    public let albumPreviewData = AlbumPreviewData()
    
    /// A Boolean flag indicating whether the user is interacting with a slider to navigate through video playback.
    public var userUsingSlider: Bool = false
    
    /// The specific file being previewed, provided during initialization.
    private let file: DJIMediaFile
    
    /// Initializes the controller with a specific media file to be previewed.
    public init(file: DJIMediaFile) {
        self.file = file
    }
    
    /// Invoked when the album view appears on screen, triggering the loading of preview media.
    public func appear() {
        if self.albumDroneController.isVideo(file: self.file) {
            self.albumPreviewData.isShowingVideo = true
            self.droneController.pushCommand(command: StartDroneVideoPlayback(file: self.file))
        } else {
            self.droneController.pushCommand(command: FetchDronePreview(file: self.file))
        }
    }
    
    /// Invoked when the album view disappears from the screen, triggering the unloading of preview media.
    public func disappear() {
        self.albumData.albumPreviewController = nil
        
        if self.albumDroneController.isVideo(file: self.file) {
            self.droneController.pushCommand(command: StopDroneVideoPlayback())
        } else {
            self.file.resetPreview()
        }
    }
    
    /// Provides a view that displays the content suitable for preview within the album, such as images or videos.
    public func getPreviewableContent() -> any View {
        VStack {
            if self.albumPreviewData.isShowingVideo {
                AlbumDroneVideoPlayback()
            } else {
                if self.file.preview != nil {
                    Image(uiImage: self.file.preview!).resizable().scaledToFit()
                }
            }
        }.onReceive(self.droneData.$deviceConnected) { newValue in
            if !newValue {
                self.viewController.displayPreviousView()
            }
        }
    }
    
    /// Supplies additional information to be displayed on the top bar of the preview interface, like current media metadata.
    public func getAdditionalTopBarInfo() -> any View {
        HStack(spacing: 20) {
            Text("Low-Res Preview").bold().font(.caption).foregroundColor(.white).padding([.top], 20)
            Text(self.file.timeCreated).foregroundColor(.white).padding([.top], 15)
        }
    }
    
    /// Generates an additional button for the preview interface, potentially used for actions like sharing or editing the media.
    public func getAdditionalButton() -> any View {
        let disab: Bool = self.droneData.mediaDownloadState != nil || self.albumDroneController.isMediaSaved(file: self.file)
        
        return Image(systemName: "tray.and.arrow.down").font(.title2).padding([.top], 10)
            .foregroundColor(disab ? .gray : .white).onTapGesture {
                self.albumDroneController.saveFiles(files: [self.file])
            }.disabled(disab)
    }
    
    /// Resumes video playback if the current preview content is a video.
    public func resumeVideo() { CRFly.shared.droneController.pushCommand(command: ResumeDroneVideoPlayback()) }
    
    /// Pauses video playback if the current preview content is a video.
    public func pauseVideo() { CRFly.shared.droneController.pushCommand(command: PauseDroneVideoPlayback()) }
    
    /// Handles changes in video playback based on user interaction with a slider component (e.g., seeking).
    public func sliderEditingChanged(action: Bool) {
        self.userUsingSlider = true
        if !action {
            CRFly.shared.droneController.pushCommand(command: ChangeVideoTimeDronePlayback(file: self.file))
        }
    }
    
    /// Moves previewed media file to trash, effectively deleting them from the album.
    public func trashFile() {
        self.disappear()
        self.albumDroneController.trashFiles(files: [self.file])
    }
    
    /// Initiates the upload of previewed media file to a designated location.
    public func uploadFile() { self.droneController.uploadFiles(files: [self.file]) }
}
