import AVKit
import SwiftUI

/// `AlbumSavedPreviewController` is a concrete implementation of the `AlbumPreviewController` protocol tailored for displaying preview of media saved in `AlbumSavedController`. It provides functionality for media handling actions within the saved albums context.
public class AlbumSavedPreviewController: AlbumPreviewController {
    /// Reference to an instance of `SceneController` that manages broader scene-related operations.
    private let sceneController: SceneController
    
    /// Reference to an instance of `AlbumSavedController` that manages the overall album of saved media.
    private let albumSavedController: AlbumSavedController
    
    /// Reference to the observable data class `AlbumPreviewData`  that provides the necessary context and details for the previewed album.
    public let albumPreviewData = AlbumPreviewData()
    
    /// An optional AVPlayer used to manage playback of video files within the preview.
    private var videoPlayer: AVPlayer? = nil
    
    /// A token used for managing time observation on the video player to update the UI based on the current playback time.
    private var timeObserverToken: Any? = nil
    
    /// The specific file being previewed, provided during initialization.
    private let file: DocURL
    
    /// Initializes a new instance of `AlbumSavedPreviewController`.
    public init(file: DocURL, albumSavedController: AlbumSavedController, sceneController: SceneController) {
        self.file = file
        self.albumSavedController = albumSavedController
        self.sceneController = sceneController
    }
    
    /// Invoked when the album view appears on screen, triggering the loading of preview media.
    public func appear() {
        if self.albumSavedController.isVideo(file: self.file) {
            if self.videoPlayer == nil {
                self.videoPlayer = AVPlayer(url: self.file.getURL())
            }
            if let duration = videoPlayer!.currentItem?.asset.duration { self.albumPreviewData.videoTotalTime = duration.seconds }
            self.albumPreviewData.isShowingVideo = true
            self.albumPreviewData.isPlayingVideo = true
            self.addPeriodicTimeObserver()
            self.videoPlayer?.play()
        }
        self.albumPreviewData.previewLoading = false
    }
    
    /// Invoked when the album view disappears from the screen, triggering the unloading of preview media.
    public func disappear() {
        if self.albumSavedController.isVideo(file: self.file) {
            self.videoPlayer?.pause()
            if let timeObserverToken {
                self.videoPlayer?.removeTimeObserver(timeObserverToken)
                self.timeObserverToken = nil
            }
            self.videoPlayer = nil
        }
        self.albumSavedController.albumData.albumPreviewController = nil
    }
    
    /// Provides a view that displays the content suitable for preview within the album, such as images or videos.
    public func getPreviewableContent() -> any View {
        VStack {
            if self.albumPreviewData.isShowingVideo, self.videoPlayer != nil {
                SavedVideoPlayer(player: self.videoPlayer!)
                    .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: self.videoPlayer?.currentItem)) { _ in
                        self.videoPlayer?.seek(to: .zero)
                        if self.albumPreviewData.isPlayingVideo {
                            self.videoPlayer?.play()
                        }
                    }
            } else {
                AsyncImage(url: self.file.getURL()) { image in image.resizable().aspectRatio(contentMode: .fit) }
            placeholder: { ProgressView() }
            }
        }
    }
    
    /// Resumes video playback if the current preview content is a video.
    public func resumeVideo() {
        if self.albumPreviewData.isShowingVideo {
            self.videoPlayer?.play()
            self.albumPreviewData.isPlayingVideo = true
        }
    }
    
    /// Pauses video playback if the current preview content is a video.
    public func pauseVideo() {
        if self.albumPreviewData.isShowingVideo {
            self.videoPlayer?.pause()
            self.albumPreviewData.isPlayingVideo = false
        }
    }
    
    /// Handles changes in video playback based on user interaction with a slider component (e.g., seeking).
    public func sliderEditingChanged(action: Bool) {
        if self.albumPreviewData.isShowingVideo {
            if action { self.videoPlayer?.pause() }
            else {
                let newTime = CMTime(seconds: self.albumPreviewData.videoCurrentTime, preferredTimescale: 600)
                self.videoPlayer?.seek(to: newTime) { [self] _ in
                    if self.albumPreviewData.isPlayingVideo {
                        self.videoPlayer?.play()
                    }
                }
            }
        }
    }
    
    /// Moves previewed media file to trash, effectively deleting them from the album.
    public func trashFile() {
        self.disappear()
        self.albumSavedController.trashFiles(files: [self.file])
    }
    
    /// Initiates the upload of previewed media file to a designated location.
    public func uploadFile() {
        self.sceneController.uploadMedia(files: [self.file], waitDownload: [])
    }
    
    // MARK: Extension methods
    
    /// Adds a periodic observer to the video player to update the playback position in the UI. This method sets up an observer that fires every 0.1 seconds during video playback.
    private func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        self.timeObserverToken = self.videoPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [self] time in
            self.albumPreviewData.videoCurrentTime = time.seconds
        }
    }
    
    /// A `UIViewControllerRepresentable` that encapsulates the functionality to integrate an AVPlayer into SwiftUI views, used specifically for playing videos within the album preview.
    public struct SavedVideoPlayer: UIViewControllerRepresentable {
        private let player: AVPlayer
        
        /// Initializes a new video player view representable with the specified AVPlayer.
        public init(player: AVPlayer) {
            self.player = player
        }
        
        /// Creates and returns an `AVPlayerViewController` instance configured with the associated AVPlayer. This view controller does not show playback controls by default.
        public func makeUIViewController(context _: Context) -> AVPlayerViewController {
            let controller = AVPlayerViewController()
            controller.player = self.player
            controller.showsPlaybackControls = false
            
            return controller
        }
        
        /// Updates the configuration of the `AVPlayerViewController` during SwiftUI state updates, but is left empty as the player configuration does not change in this implementation.
        public func updateUIViewController(_: AVPlayerViewController, context _: Context) {}
    }
}
