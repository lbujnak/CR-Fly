import SwiftUI
import DJISDK

public class DroneAlbumController: AlbumController {
    @Published var selectedItems : [DJIMediaFile] = []
    @Published var albumItems: [Date: [DJIMediaFile]] = [:]
    private let columns = [GridItem(.adaptive(minimum: 140),alignment: .center)]
    
    //*****************************************//
    //        MARK: override functions
    //*****************************************//
    public override func appear() {
        super.appear()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)){
            CRFly.shared.droneController.pushCommand(command: EnterDroneAlbum(albumController: self))
        }
    }
    
    public override func toggleSelectMode() {
        super.toggleSelectMode()
        self.selectedItems.removeAll()
    }
    
    public override func toggleFilter(newFilter: MediaFilter) {
        self.filter = newFilter
        for (_,files) in self.albumItems {
            for file in files {
                if(self.fileAcceptFilter(file: file, filter: self.filter)) {
                    self.albumEmpty = false
                    return
                }
            }
        }
        self.albumEmpty = true
    }
    
    public override func getTitle(appData: ApplicationData) -> any View {
        return HStack{
            Image(systemName: "app.connected.to.app.below.fill")
            Text(appData.djiDevice != nil ? DJISDKManager.product()!.model! : "Aircraft Album")
        }
    }
    
    public override func getSelectCount() -> Int {
        return self.selectedItems.count
    }
    
    public override func getSelectStatus() -> any View {
        if(self.selectedItems.count == 0) {
            return Text("Select Items")
        }
        else {
            var total: Int64 = 0
            for obj in self.selectedItems { total += obj.fileSizeInBytes }
            return AlbumView.generateSelectText(totalBytes: Double(total/1000000), itemCount: self.selectedItems.count)
        }
    }
    
    public override func getAlbumContent(appData: ApplicationData) -> any View {
        return VStack {
            ForEach(self.albumItems.sorted(by: { $0.key > $1.key }), id: \.key) { [self] (date, files) in
                if(self.arrayAcceptFilter(files: files, filter: self.filter)){
                    Section(header:
                                HStack{
                        Text(date.description.prefix(10)).font(.custom("date", size: 15)).bold().padding(.top, 20.0).foregroundColor(.gray)
                        Spacer()
                    }
                    ){
                        LazyVGrid(columns: columns, spacing: 5) {
                            ForEach(files, id: \.self){ (file) in
                                if(self.fileAcceptFilter(file: file , filter: self.filter)){
                                    AnyView(self.createFileThumbnail(file: file, appData: appData))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    public override func getSpecialButtons(appData: ApplicationData) -> any View {
        return Group {
            if(CRFly.shared.savedAlbumController.mediaSavable){
                let dwnldDisabled = appData.mediaDownloadState != nil || self.getSelectCount() == 0
                
                Image(systemName: "tray.and.arrow.down").foregroundColor(dwnldDisabled ? .secondary : .primary)
                .onTapGesture {
                    self.saveFiles(files: self.selectedItems)
                    self.toggleSelectMode()
                }.disabled(dwnldDisabled)
            }
        }
    }
    
    public override func selectAll() { self.selectedItems = self.albumItems.flatMap { $0.value } }
    public override func unselectAll() { self.selectedItems.removeAll() }
    
    public override func trashSelected() {
        self.trashFiles(files: self.selectedItems)
        self.toggleSelectMode()
    }
    
    public override func uploadSelected() {
        //TODO:
        return
    }
    
    //*****************************************//
    //          MARK: class functions
    //*****************************************//
    public func addToAlbum(file: DJIMediaFile){
        let fileDateString = String(file.timeCreated.prefix(10))
        let fileDate = SimpleDateFormatter().date(from: fileDateString)!
        
        if let _ = self.albumItems[fileDate] {
            self.albumItems[fileDate]!.append(file)
        } else {
            self.albumItems[fileDate] = [file]
        }
        
        if(self.albumEmpty && self.fileAcceptFilter(file: file, filter: self.filter)) {
            self.albumEmpty = false
        }
        self.albumLoading = false
    }
    
    public func saveFiles(files: [DJIMediaFile]){
        print("save call with \(String(describing: files.first?.fileName))")
        CRFly.shared.droneController.pushCommand(command: DownloadDroneMedia(files: files))
    }
    
    public func trashFiles(files: [DJIMediaFile]){
        print("trash call with \(String(describing: files))")
        CRFly.shared.droneController.pushCommand(command: RemoveDroneMedia(files: files, albumController: self))
        self.toggleFilter(newFilter: self.filter)
    }
    
    public func cleanAlbum() {
        self.albumItems.removeAll()
        self.albumEmpty = true
    }
    
    public func isMediaSaved(file: DJIMediaFile) -> Bool {
        return CRFly.shared.savedAlbumController.isMediaSaved(file: file)
    }
    
    public func isPhoto(file: DJIMediaFile) -> Bool{
        if(file.mediaType == DJIMediaType.JPEG || file.mediaType == DJIMediaType.RAWDNG){ return true }
        return false
    }
    
    public func isPano(file: DJIMediaFile) -> Bool{
        if(file.mediaType == DJIMediaType.panorama){ return true }
        return false
    }
    
    public func isVideo(file: DJIMediaFile) -> Bool{
        if(file.mediaType == DJIMediaType.MOV || file.mediaType == DJIMediaType.MP4) { return true }
        return false
    }
    
    //*****************************************//
    //    MARK: inner-class helper functions
    //*****************************************//
    private func arrayAcceptFilter(files: [DJIMediaFile], filter: MediaFilter) -> Bool{
        for file in files {
            if(self.fileAcceptFilter(file: file, filter: self.filter)){
                return true
            }
        }
        return false
    }
    
    private func fileAcceptFilter(file: DJIMediaFile, filter: MediaFilter) -> Bool{
        switch(filter){
            case .all: return true
            case .photos: return self.isPano(file: file) || self.isPhoto(file: file)
            case .videos: return self.isVideo(file: file)
        }
    }
    
    private func createFileThumbnail(file: DJIMediaFile, appData: ApplicationData) -> any View {
        return ZStack {
            Image(uiImage: self.isVideo(file: file) ? file.thumbnail! : file.preview!).resizable().scaledToFill().frame(width: 140, height: 100).clipped()
                .foregroundColor(self.selectedItems.contains(file) ? .blue : .white)
                .onTapGesture {
                    if(!self.selectedItems.contains(file)){
                        if(self.selectMode) { self.selectedItems.append(file) }
                        else {
                            CRFly.shared.viewController.changeView(view: AnyView(AlbumPreviewView(appData: appData, previewController: DroneAlbumPreviewController(albumController: self, file: file))), type: .albumMediaPreview)
                        }
                    } else {
                        self.selectedItems.remove(at: self.selectedItems.firstIndex(of: file)!)
                    }
                }
            VStack {
                HStack {
                    if(!CRFly.shared.savedAlbumController.isMediaSaved(file: file)){
                        let contains = appData.mediaDownloadState != nil && appData.mediaDownloadState!.downloadList.contains(file)
                        Image(systemName: "tray.and.arrow.down.fill").foregroundColor(contains ? .blue : .white).padding([.trailing, .top],4).font(.custom("dwnld", size: 15))
                    }
                    /*
                     if(!self.rcProjectManagement.currentProject.fileList.contains(file.fileName)){
                     if(self.libController.isPhoto(file: file) || self.libController.isPano(file: file)){
                     Image(systemName: "square.and.arrow.up.fill").foregroundColor(.white).padding([.trailing, .top],4).font(.custom("dwnld", size: 15))
                     } else {
                     Image(systemName: "square.and.arrow.up.fill").foregroundColor(.red).padding([.trailing, .top],4).font(.custom("dwnld", size: 15))
                     }
                     }*/
                    
                    Spacer()
                    if(self.selectMode){
                        Image(systemName: self.selectedItems.contains(file) ? "checkmark.square.fill": "square").foregroundColor(self.selectedItems.contains(file) ? .blue : .white).padding([.trailing, .top],4).font(.custom("checkbox", size: 15))
                    }
                }
                
                Spacer()
                HStack{
                    if(self.isVideo(file: file)) { Image(systemName: "video.fill").foregroundColor(.white).padding([.leading, .bottom],4).font(.custom("fileType", size: 15)) }
                    else if(self.isPhoto(file: file)){ Image(systemName: "photo.fill").foregroundColor(.white).padding([.leading, .bottom],4).font(.custom("fileType", size: 15)) }
                    else if(self.isPano(file: file)){ Image(systemName: "pano.fill").foregroundColor(.white).padding([.leading, .bottom],4).font(.custom("fileType", size: 15)) }
                    else{ Image(systemName: "camera.metering.unknown").foregroundColor(.white) }
                    Spacer()
                }
            }
        }.frame(width: 140)
    }
}
