import SwiftUI
import DJISDK

public class DroneAlbumPreviewController: AlbumPreviewController {
    
    private var file: DJIMediaFile
    @Published var userUsingSlider: Bool = false
    
    private var albumController: DroneAlbumController
    @ObservedObject private var appData = CRFly.shared.appData
    
    init(albumController: DroneAlbumController, file: DJIMediaFile) {
        self.file = file
        self.albumController = albumController
        super.init()
    }
    
    //*****************************************//
    //        MARK: override functions
    //*****************************************//
    public override func appear() {
        self.appData.droneAlbumPreviewController = self
        if(self.albumController.isVideo(file: self.file)){
            self.isShowingVideo = true
            CRFly.shared.droneController.pushCommand(command: StartDroneVideoPlayback(file: self.file))
        } else {
            self.previewLoading = false
        }
    }
    
    public override func disappear() {
        self.appData.droneAlbumPreviewController = nil
        if(self.albumController.isVideo(file: self.file)){
            CRFly.shared.droneController.pushCommand(command: StopDroneVideoPlayback())
        } 
    }
    
    public override func getPreviewableContent() -> any View {
        return VStack {
            if(self.isShowingVideo){
                AlbumDroneVideoPlayback()
            } else {
                if(self.file.preview != nil){
                    Image(uiImage: self.file.preview!).resizable().scaledToFit()
                }
            }
        }.onReceive(self.appData.$djiDevConn) { newValue in
            if (!newValue) {
                CRFly.shared.viewController.changeView(type: .albumView)
            }
        }
    }
    
    public override func getAdditionalTopBarInfo() -> any View {
        return HStack(spacing: 20) {
            Text("Low-Res Preview").bold().font(.caption).foregroundColor(.white).padding([.top],20)
            Text(self.file.timeCreated).foregroundColor(.white).padding([.top],15)
        }
    }
    
    public override func getAdditionalButton() -> any View {
        let disab : Bool = self.appData.mediaDownloadState != nil || self.albumController.isMediaSaved(file: self.file)
        
        return Image(systemName: "tray.and.arrow.down").font(.title2).padding([.top],10)
            .foregroundColor(disab ? .secondary : .primary).onTapGesture {
            self.albumController.saveFiles(files: [self.file])
        }.disabled(disab)
    }
    
    public override func resumeVideo() { CRFly.shared.droneController.pushCommand(command: ResumeDroneVideoPlayback()) }
    public override func pauseVideo() { CRFly.shared.droneController.pushCommand(command: PauseDroneVideoPlayback()) }
    public override func sliderEditingChanged(action: Bool) {
        self.userUsingSlider = true
        if(!action){
            CRFly.shared.droneController.pushCommand(command: ChangeVideoTimeDronePlayback(file: self.file))
        }
        print("sliderchange \(self.userUsingSlider) and \(action)")
    }
    public override func trashFile() { self.albumController.trashFiles(files: [self.file]) }
}
