import SwiftUI
import AVKit

public class SavedAlbumPreviewController: AlbumPreviewController {
    
    private var file: URL
    private var albumController: SavedAlbumController
    
    private var videoPlayer: AVPlayer? = nil
    @State private var timeObserverToken: Any? = nil
    
    init(albumController: SavedAlbumController, file: URL) {
        self.file = file
        self.albumController = albumController
        super.init()
    }
    
    //*****************************************//
    //        MARK: override functions
    //*****************************************//
    public override func appear() {
        if(self.albumController.isVideo(file: self.file)){
            self.videoPlayer = AVPlayer(url: self.file)
            if let duration = self.videoPlayer!.currentItem?.asset.duration { self.videoTotalTime = duration.seconds }
            self.isShowingVideo = true
            self.isPlayingVideo = true
            self.addPeriodicTimeObserver()
            self.videoPlayer!.play()
        }
        self.previewLoading = false
    }
    
    public override func disappear() {
        if(self.albumController.isVideo(file: self.file)){
            self.videoPlayer!.pause()
            if let timeObserverToken = timeObserverToken {
                self.videoPlayer!.removeTimeObserver(timeObserverToken)
                self.timeObserverToken = nil
            }
        }
    }
    
    public override func getPreviewableContent() -> any View {
        return VStack {
            if(self.isShowingVideo){
                SavedVideoPlayer(player: self.videoPlayer!).onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: self.videoPlayer!.currentItem)) { _ in
                    self.videoPlayer!.seek(to: .zero)
                    if(self.isPlayingVideo){ self.videoPlayer!.play() }
                }
            } else {
                AsyncImage(url: self.file) { image in image.resizable().aspectRatio(contentMode: .fit) }
                    placeholder: { ProgressView() }
            }
        }
    }
    
    public override func resumeVideo() {
        if(self.isShowingVideo){
            self.videoPlayer!.play()
            self.isPlayingVideo = true
        }
    }
    
    public override func pauseVideo() {
        if(self.isShowingVideo){
            self.videoPlayer!.pause()
            self.isPlayingVideo = false
        }
    }
    
    public override func sliderEditingChanged(action: Bool) {
        if(self.isShowingVideo){
            if(action) { self.videoPlayer!.pause() }
            else {
                let newTime = CMTime(seconds: self.videoCurrentTime, preferredTimescale: 600)
                self.videoPlayer!.seek(to: newTime) { [self] _ in
                    if(self.isPlayingVideo) {
                        self.videoPlayer!.play()
                    }
                }
            }
        }
    }
    
    public override func trashFile() { self.albumController.trashFiles(files: [self.file]) }
    
    //*****************************************//
    //    MARK: inner-class helper functions
    //*****************************************//
    private func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = self.videoPlayer!.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [self] time in
            self.videoCurrentTime = time.seconds
        }
    }
    
    struct SavedVideoPlayer: UIViewControllerRepresentable {
        let player: AVPlayer
        
        func makeUIViewController(context: Context) -> AVPlayerViewController {
            let controller = AVPlayerViewController()
            controller.player = player
            controller.showsPlaybackControls = false
            return controller
        }
        
        func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        }
    }
}

