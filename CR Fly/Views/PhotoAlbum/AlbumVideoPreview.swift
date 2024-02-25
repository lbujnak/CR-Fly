import SwiftUI
import DJISDK

struct AlbumVideoPreview: View {
    var file: DJIMediaFile
    @Binding var currController: AlbumController
    
    @State var showingMediaControls: Bool = true
    @ObservedObject var appData = CRFly.shared.appData
    
    var body: some View {
        ZStack{
            /*Color.black.ignoresSafeArea()
            HStack{
                AlbumDroneVideoPlayback()//.ignoresSafeArea().opacity((self.appData.djiMediaPreviewState != nil) ? 1 : 0)
            }
            
            VStack{
                //MARK: Top Bar - download/up information, back button, etc..
                if(self.showingMediaControls) {
                    VStack {
                        //Dowload and Upload information
                        AlbumHelper.createDwnUpInfo(appData: self.appData).padding([.top],5)
                        
                        //Back
                        HStack(alignment: .top, spacing: 30){
                            Button("←"){
                                CRFly.shared.viewController.changeView(type: .albumView)
                                self.appData.djiMediaPreviewState = nil
                                if(!AlbumHelper.isVideo(file: self.file)){
                                    CRFly.shared.droneController.pushCommand(command: ExitDronePreview(file: self.file))
                                }
                            }.foregroundColor(.white).font(.largeTitle)
                            
                            Spacer()
                            Text("Low-Res Preview").bold().font(.caption).foregroundColor(.white).padding([.top],20)
                            Text(self.file.timeCreated).foregroundColor(.white).padding([.top],15)
                            Spacer()
    
                            let disab : Bool = self.appData.mediaDownloadState != nil || self.appData.mediaUploadState != nil/* || !self.rcProjectManagement.currentProject.loaded*/
                            Image(systemName: "square.and.arrow.up").font(.title2).padding([.top],10).foregroundColor(disab ? Color.gray : Color.white)
                            .onTapGesture {
                                //self.libController.prepareFilesToUpload(selected: [self.libController.mediaLibPicked!])
                            }.disabled(disab)
                        }
                    }
                }
                            
                //Play,Pause buttons,Loading
                Spacer()
                if(self.appData.djiMediaPreviewState == nil){
                    ProgressView().scaleEffect(x: 2, y: 2, anchor: .center).progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                            
                //Controls for video - > Play and pause btn
                if(self.showingMediaControls && AlbumHelper.isVideo(file: self.file)) {
                    if(self.appData.djiMediaPreviewState != nil) {
                        if(!self.appData.djiMediaPreviewState!.isPlaying){
                            Image(systemName: "play.circle.fill").font(.custom("PlayPause", size: 70)).foregroundColor(.white).onTapGesture {
                                self.showingMediaControls = false
                                CRFly.shared.droneController.pushCommand(command: ResumeDroneVideoPlayback())
                            }
                        } else {
                            Image(systemName: "pause.circle.fill").font(.custom("PlayPause", size: 70)).foregroundColor(.white).onTapGesture {
                                self.showingMediaControls = false
                                CRFly.shared.droneController.pushCommand(command: PauseDroneVideoPlayback())
                            }
                        }
                    }
                }
                            
                Spacer()
                //MARK: Bottom Bar
                if(self.showingMediaControls) {
                    HStack{
                        //Remove previewing file
                        Image(systemName: "trash").font(.title2).foregroundColor(.white).onTapGesture {
                            if(!AlbumHelper.isVideo(file: self.file)) {
                                CRFly.shared.droneController.pushCommand(command: ExitDronePreview(file: self.file))
                            } else {
                                
                            }
                            CRFly.shared.droneController.pushCommand(command: RemoveDroneMedia(files: [self.file]))
                            CRFly.shared.viewController.changeView(type: .albumView)
                        }
                                
                        Spacer()
                        //Slider, time and stats of previewed video
                        if(AlbumHelper.isVideo(file: self.file) && self.appData.djiMediaPreviewState != nil){
                            HStack {
                                let elapsedTime = Binding(
                                    get: { Double(self.appData.djiMediaPreviewState?.currentTime ?? 0) },
                                    set: { self.appData.djiMediaPreviewState?.currentTime = Float($0) }
                                )
                            
                                let totalVideoTime = self.appData.djiMediaPreviewState!.totalTime
                            
                                let elapsed = AlbumHelper.secondsToVideoTime(seconds: Int(self.appData.djiMediaPreviewState!.currentTime))
                                let total = AlbumHelper.secondsToVideoTime(seconds: Int(totalVideoTime))
                                
                                if(totalVideoTime >= 3600){ Text(String(format: "%.2i:%.2i:%.2i",elapsed.hours,elapsed.minutes,elapsed.seconds)).foregroundColor(.white) }
                                else { Text(String(format: "%.2i:%.2i",elapsed.minutes,elapsed.seconds)).foregroundColor(.white) }
                                        
                                Slider(value: elapsedTime, in: 0...Double(totalVideoTime), onEditingChanged: {(chg) in
                                    self.appData.djiMediaPreviewState!.isUserChangingTime = true
                                    if(!chg) {
                                        CRFly.shared.droneController.pushCommand(command: ChangeVideoTimeDronePlayback())
                                    }
                                }).tint(.white).onAppear(){
                                    let thumbImage = ImageRenderer(content: bullThumb).uiImage ?? UIImage()
                                    UISlider.appearance().setThumbImage(thumbImage, for: .normal)
                                }
                            
                                if(totalVideoTime >= 3600){ Text(String(format: "%.2i:%.2i:%.2i",total.hours,total.minutes,total.seconds)).foregroundColor(.white) }
                                else { Text(String(format: "%.2i:%.2i",total.minutes,total.seconds)).foregroundColor(.white) }
                            }.frame(width: 400)
                        }
                        
                        Spacer()
                        let disab : Bool = self.appData.mediaDownloadState != nil || CRFly.shared.isMediaSaved(file: self.file)
                        
                        Image(systemName: "tray.and.arrow.down").font(.title2).padding([.top],10).foregroundColor(disab ? Color.gray : Color.white)
                        .onTapGesture {
                            CRFly.shared.droneController.pushCommand(command: DownloadDroneMedia(files: [self.file]))
                        }.disabled(disab)
                    }
                }
            }*/
        }.onTapGesture { self.showingMediaControls.toggle() }
        .onAppear(perform: self.prepareDrone)
    }
    
    private func prepareDrone() {
        self.appData.djiMediaPreviewState = nil
        CRFly.shared.droneController.pushCommand(command: PrepareDroneVideoPlayback(file: self.file))
    }
    
    private var bullThumb: some View {
        ZStack {
            Circle().frame(width: 25, height: 25).foregroundColor(.white)
        }.foregroundColor(.blue)
    }
}
