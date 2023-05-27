import SwiftUI
import DJISDK

struct LibraryPreviewView: View {
    
    @ObservedObject var djiService = ProductCommunicationService.shared
    @ObservedObject var rcNodeService = RCNodeCommunicationService.shared
    @ObservedObject var libController = ProductCommunicationService.shared.libController
    @ObservedObject var alertHelper = GlobalAlertHelper.shared
    
    @State var showingMediaControls : Bool = true
    
    var body: some View {
        VStack{
            if(self.libController.mediaLibPicked != nil){
                ZStack{
                    Color.black.ignoresSafeArea()
                    HStack{
                        //Image or video to show
                        if(self.libController.mediaLibPicked != nil){
                            if(self.isVideo(file: self.libController.mediaLibPicked!)) {
                                VPView().background(Color.black.ignoresSafeArea()).ignoresSafeArea().opacity((self.libController.mediaPreviewReady) ? 1 : 0)
                            } else if(self.libController.mediaPreviewReady){
                                Image(uiImage: self.libController.mediaLibPicked!.preview!).resizable().scaledToFit()
                            }
                        }
                    }
                    VStack{
                        if(self.showingMediaControls) { self.createTopBar() }
                        
                        //Play,Pause buttons,Loading
                        Spacer()
                        if(!self.libController.mediaPreviewReady){
                            ProgressView().scaleEffect(x: 4, y: 4, anchor: .center).progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        
                        //Controls for video - > Play and pause btn
                        if(self.isVideo(file: self.libController.mediaLibPicked) && self.libController.mediaPreviewReady) {
                            if(!self.libController.mediaPreviewVideoPlaying && self.libController.mediaPreviewReady){
                                Image(systemName: "play.circle.fill").font(.custom("PlayPause", size: 70)).foregroundColor(.white).onTapGesture {
                                    self.libController.resumeVideo(completionHandler: {(error) in
                                        if(error != nil){
                                            GlobalAlertHelper.shared.createAlert(title: "Error", msg: "Error resuming video: \( error!)")
                                            return
                                        }
                                        self.libController.mediaPreviewVideoPlaying = true
                                        self.showingMediaControls = false
                                    })
                                }
                            }
                            else if(self.libController.mediaPreviewVideoPlaying && self.showingMediaControls){
                                Image(systemName: "pause.circle.fill").font(.custom("PlayPause", size: 70)).foregroundColor(.white).onTapGesture {
                                    self.libController.pauseVideo(completionHandler: {(error) in
                                        if(error != nil){
                                            GlobalAlertHelper.shared.createAlert(title: "Error", msg: "Error resuming video: \(error!)")
                                            return
                                        }
                                        self.libController.mediaPreviewVideoPlaying = false
                                    })
                                }
                            }
                        }
                        
                        Spacer()
                        if(self.showingMediaControls) { self.createBottomBar() }
                    }
                }
            }
        }.alert(isPresented: self.$alertHelper.active){ Alert(title: self.alertHelper.title, message: self.alertHelper.msg, dismissButton: .cancel()) }
            .onTapGesture { self.showingMediaControls.toggle() }
    }
    
    private func createTopBar() -> some View{
        VStack{
            if(self.libController.mediaDownloading){ self.createDownloadInfo() }
            HStack(alignment: .top, spacing: 30){
                Button("←"){
                    if(self.isVideo(file: self.libController.mediaLibPicked!)) {
                        self.libController.stopVideo(completionHandler: {(error) in
                            if(error != nil) {
                                GlobalAlertHelper.shared.createAlert(title: "Error", msg: "Error while stopping video: \(error!)")
                                return
                            }
                        })
                    }
                    DispatchQueue.main.async {
                        self.libController.exitPreviewMode()
                        ViewHelper.shared.libModePicked = false
                    }
                }.foregroundColor(.white).font(.largeTitle)
                
                Spacer()
                Text("Low-Res Preview").bold().font(.caption).foregroundColor(.white).padding([.top],20)
                if(self.libController.mediaLibPicked != nil){
                    Text(self.libController.mediaLibPicked!.timeCreated).foregroundColor(.white).padding([.top],15)
                }
                Spacer()
                
                let disab : Bool = self.libController.mediaDownloading || self.libController.mediaUploading || !self.rcNodeService.currentProject.loaded
                Image(systemName: "square.and.arrow.up").font(.title2).padding([.top],10).foregroundColor(disab ? Color.gray : Color.white).onTapGesture {
                    self.libController.prepareFilesToUpload(selected: [self.libController.mediaLibPicked!])
                }.disabled(disab)
            }
        }
    }
    
    private func createBottomBar() -> some View{
        HStack{
            //Remove previewing file
            Image(systemName: "trash").font(.title2).foregroundColor(.white).onTapGesture {
                ViewHelper.shared.libModePicked = false
                self.libController.removePreviewFile(completionHandler: {(error) in
                    if(error != nil) {
                        GlobalAlertHelper.shared.createAlert(title: "Error", msg: "There was an error during removing selected files: \(error!)")
                    }
                    self.libController.exitPreviewMode()
                })
            }
            
            Spacer()
            
            //Slider, time and stats of previewed video
            if(self.isVideo(file: self.libController.mediaLibPicked!)){
                let totalTime : Double = Double(Int(self.libController.mediaLibPicked!.durationInSeconds))
                
                let elapsedTime = Binding(
                    get: { Double(self.libController.mediaPreviewVideoCTime) },
                    set: { self.libController.mediaPreviewVideoCTime = Int($0) }
                )
                HStack{
                    let elapsed = secondsToVideoTime(seconds: self.libController.mediaPreviewVideoCTime)
                    let total = secondsToVideoTime(seconds: Int(self.libController.mediaLibPicked!.durationInSeconds))
                    
                    if(totalTime >= 3600){ Text(String(format: "%.2i:%.2i:%.2i",elapsed.hours,elapsed.minutes,elapsed.seconds)).foregroundColor(.white) }
                    else { Text(String(format: "%.2i:%.2i",elapsed.minutes,elapsed.seconds)).foregroundColor(.white) }
                    
                    Slider(value: elapsedTime, in: 0...totalTime ,onEditingChanged: {(chg) in
                        self.libController.mediaPreviewVideoChanging = chg
                        if(!chg) {
                            self.libController.changeVideoPreviewTime(time: Float(self.libController.mediaPreviewVideoCTime), completionHandler: {(error) in
                                if(error != nil){
                                    GlobalAlertHelper.shared.createAlert(title: "Error", msg: "There was an error during changing preview time: \(error!)")
                                }
                            })
                        }
                    }).tint(.white).onAppear(){
                        let thumbImage = ImageRenderer(content: bullThumb).uiImage ?? UIImage()
                        UISlider.appearance().setThumbImage(thumbImage, for: .normal)
                    }
                    
                    if(totalTime >= 3600){ Text(String(format: "%.2i:%.2i:%.2i",total.hours,total.minutes,total.seconds)).foregroundColor(.white) }
                    else { Text(String(format: "%.2i:%.2i",total.minutes,total.seconds)).foregroundColor(.white) }
                }.frame(width: 400)
            }
            Spacer()
            let disab : Bool = self.libController.mediaDownloading || self.libController.mediaSaved(file: self.libController.mediaLibPicked!)
            Image(systemName: "tray.and.arrow.down").font(.title2).padding([.top],10).foregroundColor(disab ? Color.gray : Color.white).onTapGesture {
                self.libController.prepareAndDownload(selected: [self.libController.mediaLibPicked!])
            }.disabled(disab)
        }
    }
    
    private func createDownloadInfo() -> some View {
        VStack(spacing: 0){
            ProgressView(value: Double(self.libController.stat_dwnBytes), total: Double(self.libController.stat_totalBytes)).progressViewStyle(.linear).background(Color(red: 0.100, green: 0.100, blue: 0.100))
            
            HStack(spacing: 10){
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaledToFit().padding([.horizontal],10)
                
                let perc = Int(Float(self.libController.stat_dwnBytes) / Float(self.libController.stat_totalBytes)*100)
                Text(String(format: "%d%% Downloading files(%d/%d) %.2fMB/s", perc, self.libController.mediaDownloaded, self.libController.mediaDownloadList.count, self.libController.stat_speed)).foregroundColor(.white).font(.caption)
                
                Spacer()
                
                Image(systemName: "xmark").onTapGesture {
                    self.libController.mediaDownloadStop() { (error) in
                        if(error != nil){
                            GlobalAlertHelper.shared.createAlert(title: "Stopping download", msg: "There was a problem stopping download: " + error!)
                        }
                    }
                }.padding([.horizontal],-40).foregroundColor(.white)
            }.frame(height: 30).background(Color(red: 0.100, green: 0.100, blue: 0.100))
        }
    }
    
    private func secondsToVideoTime(seconds : Int) -> videoTime{
        let hours = seconds/3600
        let minutes = (seconds - hours*3600)/60
        let sec = (seconds - hours*3600 - minutes*60)
        return videoTime(seconds: sec, minutes: minutes, hours: hours)
    }
    
    private func isVideo(file: DJIMediaFile?) -> Bool{
        if(file == nil) { return false }
        else if(file!.mediaType == DJIMediaType.MOV || file!.mediaType == DJIMediaType.MP4) {
            return true
        } else { return false }
    }
    
    private var bullThumb: some View {
        ZStack {
            Circle().frame(width: 25, height: 25).foregroundColor(.white)
        }.foregroundColor(.blue)
    }
    
    private class videoTime{
        let seconds : Int, minutes : Int, hours : Int
        init(seconds: Int, minutes: Int, hours: Int) {
            self.seconds = seconds
            self.minutes = minutes
            self.hours = hours
        }
    }
}

struct VPView: UIViewControllerRepresentable{
    
    func makeUIViewController(context: Context) -> UIViewController{
        let storyboard = UIStoryboard(name: "VideoPlaybackView", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(identifier: "VideoPlaybackView")
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}
