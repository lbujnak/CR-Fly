import SwiftUI

/// `AlbumPreviewView` provides an interface for previewing media files, supporting interactive features like play/pause for videos, file deletion, and information display. It integrates directly with an `AlbumPreviewController` to manage media playback and user interactions.
public struct AlbumPreviewView: AppearableView {
    /// Reference to the `AlbumPreviewController` for specific `AlbumMode`.
    private var previewController: AlbumPreviewController
    
    /// Reference to the observable data class `SceneData` containing scene's operational data.
    @ObservedObject private var sceneData: SceneData
    
    /// Reference to the observable data class `AlbumPreviewData`  that provides the necessary context and details for the previewed album.
    @ObservedObject private var albumPreviewData: AlbumPreviewData
    
    /// A boolean state indicating whether media controls should be visible.
    @State private var showingMediaControls: Bool = true
    
    /// Initializes an `AlbumPreviewView`.
    public init(previewController: AlbumPreviewController, sceneData: SceneData) {
        self.previewController = previewController
        self.albumPreviewData = previewController.albumPreviewData
        self.sceneData = sceneData
    }
    
    /// Called when the object becomes visible within the user interface.
    public func appear() {
        self.previewController.appear()
    }
    
    /// Called when the object is no longer visible within the user interface.
    public func disappear() {
        self.previewController.disappear()
    }
    
    /// Constructs the user interface of the `AlbumPreviewView`, organizing the layout into zones for media display and controls.
    public var body: some View {
        ZStack {
            Color(Color.black).ignoresSafeArea()
            HStack {
                // Display preview for specific AlbumPreviewController
                AnyView(self.previewController.getPreviewableContent()).ignoresSafeArea()
            }
            
            VStack(spacing: 5) {
                
                // MARK: TopBar
                if self.showingMediaControls {
                    VStack(spacing: 10) {
                        HStack(alignment: .top, spacing: 30) {
                            Button("←") {
                                self.previewController.disappear()
                            }.foregroundColor(.white).font(.largeTitle)
                            
                            Spacer()
                            AnyView(self.previewController.getAdditionalTopBarInfo())
                            Spacer()
                            
                            let uploadDisabled = !self.sceneData.openedProject.readyToUpload
                            Image(systemName: "square.and.arrow.up").font(.title2).padding([.top], 10)
                                .foregroundColor(uploadDisabled ? .gray : .white).onTapGesture {
                                    self.previewController.uploadFile()
                                }.disabled(uploadDisabled)
                        }
                    }.padding([.top], 5)
                }
                
                // MARK: Play,Pause buttons,Loading
                
                Spacer()
                if self.albumPreviewData.previewLoading {
                    ProgressView().scaleEffect(x: 2, y: 2, anchor: .center).progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    if self.showingMediaControls, self.albumPreviewData.isShowingVideo {
                        if !self.albumPreviewData.isPlayingVideo {
                            Image(systemName: "play.circle.fill").font(.custom("PlayPause", size: 70)).foregroundColor(.white).onTapGesture {
                                self.previewController.resumeVideo()
                            }
                        } else {
                            Image(systemName: "pause.circle.fill").font(.custom("PlayPause", size: 70)).foregroundColor(.white).onTapGesture {
                                self.previewController.pauseVideo()
                            }
                        }
                    }
                }
                
                Spacer()
                
                // MARK: Bottom Bar
                
                if self.showingMediaControls {
                    HStack {
                        // Remove previewing file
                        Image(systemName: "trash").font(.title2).foregroundColor(.white)
                            .onTapGesture {
                                self.previewController.trashFile()
                            }
                        
                        Spacer()
                        // Slider, time and stats of previewed video
                        if self.albumPreviewData.isShowingVideo, !self.albumPreviewData.previewLoading {
                            HStack {
                                let elapsedTime = Binding(get: { Double(self.albumPreviewData.videoCurrentTime) },
                                                          set: { self.albumPreviewData.videoCurrentTime = $0 })
                                
                                Text(SimpleDateFormatter.formatTime(self.albumPreviewData.videoCurrentTime))
                                
                                Slider(value: elapsedTime, in: 0 ... Double(self.albumPreviewData.videoTotalTime), onEditingChanged: { chg in
                                    self.previewController.sliderEditingChanged(action: chg)
                                }).tint(.white)
                                    .onAppear {
                                        let thumbImage = ImageRenderer(content: bullThumb).uiImage ?? UIImage()
                                        UISlider.appearance().setThumbImage(thumbImage, for: .normal)
                                    }
                                
                                Text(SimpleDateFormatter.formatTime(self.albumPreviewData.videoTotalTime))
                            }.frame(width: 400)
                        }
                        
                        Spacer()
                        AnyView(self.previewController.getAdditionalButton())
                    }
                }
            }
        }.onTapGesture { self.showingMediaControls.toggle() }
    }
    
    /// Creates a view representation for a slider thumb, used within video playback controls.
    private var bullThumb: some View {
        ZStack {
            Circle().frame(width: 25, height: 25).foregroundColor(.white)
        }.foregroundColor(.blue)
    }
}
