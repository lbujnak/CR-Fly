import SwiftUI

/// `AlbumPreviewController` defines essential methods and properties for its implementations, facilitating media loading and displaying preview in `AlbumPreviewView`.
public protocol AlbumPreviewController {
    /// Provide a read-only access to the  observable data class `AlbumPreviewData`  that provides the necessary context and details for the previewed album.
    var albumPreviewData: AlbumPreviewData { get }
    
    /// Invoked when the album view appears on screen, triggering the loading of preview media.
    func appear()
    
    /// Invoked when the album view disappears from the screen, triggering the unloading of preview media.
    func disappear()
    
    /// Provides a view that displays the content suitable for preview within the album, such as images or videos.
    func getPreviewableContent() -> any View
    
    /// Supplies additional information to be displayed on the top bar of the preview interface, like current media metadata.
    func getAdditionalTopBarInfo() -> any View
    
    /// Generates an additional button for the preview interface, potentially used for actions like sharing or editing the media.
    func getAdditionalButton() -> any View
    
    /// Resumes video playback if the current preview content is a video.
    func resumeVideo()
    
    /// Pauses video playback if the current preview content is a video.
    func pauseVideo()
    
    /// Handles changes in video playback based on user interaction with a slider component (e.g., seeking).
    func sliderEditingChanged(action: Bool)
    
    /// Deletes the currently previewed media file.
    func trashFile()
    
    /// Initiates the upload of previewed media file to a designated location.
    func uploadFile()
}

public extension AlbumPreviewController {
    /// Supplies additional information to be displayed on the top bar of the preview interface, like current media metadata.
    func getAdditionalTopBarInfo() -> any View { EmptyView() }
    
    /// Generates an additional button for the preview interface, potentially used for actions like sharing or editing the media.
    func getAdditionalButton() -> any View { EmptyView() }
}
