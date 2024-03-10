import SwiftUI
import DJISDK

struct AlbumPreviewView: View {
    @State var showingMediaControls: Bool = true
    
    @ObservedObject var appData: ApplicationData
    @ObservedObject var previewController: AlbumPreviewController
    
    var body: some View {
        ZStack{
            Color(UIColor.systemBackground).ignoresSafeArea()
            HStack{
                AnyView(self.previewController.getPreviewableContent()).ignoresSafeArea()
            }
            
            VStack(spacing: 5){
                //MARK: Top Bar - back button, etc..
                if(self.showingMediaControls) {
                    VStack(spacing: 10) {
                        HStack(alignment: .top, spacing: 30){
                            Button("←"){
                                CRFly.shared.viewController.displayPreviousView()
                                self.previewController.disappear()
                            }.foregroundColor(.primary).font(.largeTitle)
                            
                            Spacer()
                            AnyView(self.previewController.getAdditionalTopBarInfo())
                            Spacer()
                            
                            //TODO: UPLOAD DO RC
                            //let disab : Bool = self.appData.mediaDownloadState != nil || self.appData.mediaUploadState != nil || !self.rcProjectManagement.currentProject.loaded
                            Image(systemName: "square.and.arrow.up").font(.title2).padding([.top],10).foregroundColor(/*disab ? Color.gray : Color.white*/ .secondary)
                                .onTapGesture {
                                    //self.libController.prepareFilesToUpload(selected: [self.libController.mediaLibPicked!])
                                }//.disabled(disab)
                        }
                    }.padding([.top],5)
                }
                
                //MARK: Play,Pause buttons,Loading
                Spacer()
                if(self.previewController.previewLoading){
                    ProgressView().scaleEffect(x: 2, y: 2, anchor: .center).progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    if(self.showingMediaControls && self.previewController.isShowingVideo) {
                        if(!self.previewController.isPlayingVideo){
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
                //MARK: Bottom Bar
                if(self.showingMediaControls) {
                    HStack{
                        //Remove previewing file
                        let trashDisabled = self.appData.mediaDownloadState != nil || self.appData.mediaUploadState != nil
                        Image(systemName: "trash").font(.title2).foregroundColor(trashDisabled ? .secondary : .primary).onTapGesture {
                            CRFly.shared.viewController.displayPreviousView()
                            self.previewController.trashFile()
                        }.disabled(trashDisabled)
                        
                        Spacer()
                        //Slider, time and stats of previewed video
                        if(self.previewController.isShowingVideo && !self.previewController.previewLoading){
                            HStack {
                                let elapsedTime = Binding(
                                    get: { Double(self.previewController.videoCurrentTime) },
                                    set: { self.previewController.videoCurrentTime = $0 }
                                )
                                
                                Text(SimpleDateFormatter.formatTime(self.previewController.videoCurrentTime))
                                                        
                                Slider(value: elapsedTime, in: 0...Double(self.previewController.videoTotalTime), onEditingChanged: {(chg) in
                                    self.previewController.sliderEditingChanged(action: chg)
                                }).tint(.white).onAppear(){
                                    let thumbImage = ImageRenderer(content: bullThumb).uiImage ?? UIImage()
                                    UISlider.appearance().setThumbImage(thumbImage, for: .normal)
                                }
                                                    
                                Text(SimpleDateFormatter.formatTime(self.previewController.videoTotalTime))
                            }.frame(width: 400)
                        }
                        
                        Spacer()
                        AnyView(self.previewController.getAdditionalButton())
                    }
                }
            }
        }.onTapGesture { self.showingMediaControls.toggle()
        }.onAppear(perform: self.previewController.appear)
        .onDisappear(perform: self.previewController.disappear)
    }
    
    private var bullThumb: some View {
        ZStack {
            Circle().frame(width: 25, height: 25).foregroundColor(.white)
        }.foregroundColor(.blue)
    }
}

#Preview {
    AlbumPreviewView(appData: ApplicationData(), previewController: DroneAlbumPreviewController(albumController: DroneAlbumController(), file: DJIMediaFile()))
}
