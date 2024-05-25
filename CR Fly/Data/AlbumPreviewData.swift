import Foundation

/// `AlbumPreviewData` is an observable data model class that holds state related to the preview functionality within album views.
public class AlbumPreviewData: ObservableObject {
    /// A boolean that indicates whether the current media item being previewed is a video. This is used to adjust UI components specific to video content.
    @Published var isShowingVideo: Bool = false
    
    /// A boolean that tracks the playback status of the video, i.e., whether the video is currently playing. This controls play/pause functionality and updates the UI accordingly.
    @Published var isPlayingVideo: Bool = false
    
    /// A boolean that indicates whether the preview content is loading. Useful for displaying loading indicators while media is being prepared for playback.
    @Published var previewLoading: Bool = true
    
    /// A double representing the current playback time of the video in seconds. This is used for updating playback sliders and current time labels in the UI.
    @Published var videoCurrentTime: Double = 0
    
    /// A double that holds the total duration of the video being previewed in seconds. This is essential for setting the bounds of playback sliders and displaying total video duration.
    @Published var videoTotalTime: Double = 0
}
