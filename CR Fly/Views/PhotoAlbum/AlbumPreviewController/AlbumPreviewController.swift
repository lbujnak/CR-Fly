import SwiftUI

public class AlbumPreviewController: ObservableObject, Identifiable {    
    @Published var isShowingVideo: Bool = false
    @Published var isPlayingVideo: Bool = false
    @Published var previewLoading: Bool = true
    
    @Published var videoCurrentTime: Double = 0
    @Published var videoTotalTime: Double = 0
    
    public func appear() { return }
    public func disappear() { return }
    
    public func getPreviewableContent() -> any View { return EmptyView() }
    public func getAdditionalTopBarInfo() -> any View { return EmptyView() }
    public func getAdditionalButton() -> any View { return EmptyView() }
    
    public func resumeVideo() { return }
    public func pauseVideo() { return }
    public func sliderEditingChanged(action: Bool) { return }
    
    public func trashFile() { return }
    public func uploadFile() { return }

}
