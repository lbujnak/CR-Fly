import SwiftUI
import DJISDK

public class SavedAlbumController: AlbumController {
    @Published var mediaSavable: Bool = false
    @Published var libraryURL : URL = URL(filePath: NSHomeDirectory())
    @Published var selectedItems : [URL] = []
    @Published var albumItems: [Date : [URL]] = [:]
    private let columns = [GridItem(.adaptive(minimum: 140),alignment: .center)]
    
    //*****************************************//
    //        MARK: override functions
    //*****************************************//
    public override init() {
        super.init()
        self.loadSavedMedia()
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
    
    public override func getTitle(appData: ApplicationData) -> any View { return Text("Saved") }
    public override func getSelectCount() -> Int { return self.selectedItems.count }
    
    public override func getSelectStatus() -> any View {
        if(self.selectedItems.count == 0) { return Text("Select Items") }
        else {
            var total: Int64 = 0
            for file in self.selectedItems {
                do{
                    let fileAttributes = try FileManager.default.attributesOfItem(atPath: file.path)
                    if let fileSize = fileAttributes[.size] as? NSNumber {
                        total += fileSize.int64Value
                    }
                } catch { continue }
            }
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
    
    public override func selectAll() { self.selectedItems = self.albumItems.flatMap { $0.value } }
    public override func unselectAll() { self.selectedItems.removeAll() }
    
    public override func trashSelected() {
        self.trashFiles(files: self.selectedItems)
        self.toggleSelectMode()
    }
    
    public override func uploadSelected() {
        //TODO:
        print("upload files")
    }
    
    //*****************************************//
    //         MARK: class functions
    //*****************************************//
    public func addToAlbum(file: URL){
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
            if let creationDate = attributes[.creationDate] as? Date {
                let fileDate = SimpleDateFormatter().date(from: String(creationDate.description.prefix(10)))!
                
                if let _ = self.albumItems[fileDate] {
                    self.albumItems[fileDate]!.append(file)
                } else {
                    self.albumItems[fileDate] = [file]
                }
                
                if(self.albumEmpty) { self.albumEmpty = false }
            }
        } catch {
            CRFly.shared.viewController.showSimpleAlert(title: "Error Adding Media To Saved Album", msg: Text("Error adding files to Saved Media Album: " + String(describing: error)))
        }
    }
    
    public func trashFiles(files: [URL]){
        for file in files {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
                if let creationDate = attributes[.creationDate] as? Date {
                    let fileDate = SimpleDateFormatter().date(from: String(creationDate.description.prefix(10)))!
                    
                    guard let position = self.albumItems[fileDate]!.firstIndex(of: file) else {
                        CRFly.shared.viewController.showSimpleAlert(title: "Error While Removing Saved Media", msg: Text("Trash request for file that is not in album!"))
                        return
                    }
                    self.albumItems[fileDate]!.remove(at: position)
                    try FileManager.default.removeItem(at: file)
                }
            } catch {
                CRFly.shared.viewController.showSimpleAlert(title: "Error While Removing Saved Media", msg: Text("Saved media couldn't be removed!: " + String(describing: error)))
            }
        }
        self.toggleFilter(newFilter: self.filter)
    }
    
    public func isMediaSaved(file: DJIMediaFile) -> Bool {
        let fileDateString = String(file.timeCreated.prefix(10))
        let fileDate = SimpleDateFormatter().date(from: fileDateString)!
        
        if let urls = self.albumItems[fileDate] {
            return urls.contains { $0.lastPathComponent == file.fileName }
        }
        return false
    }
    
    public func isPhoto(file: URL) -> Bool{
        let ext = file.pathExtension.lowercased()
        if(ext == "jpg" || ext == "jpeg" || ext == "rawdng") { return true }
        return false
    }
    
    public func isVideo(file: URL) -> Bool{
        let ext = file.pathExtension.lowercased()
        if(ext == "mov" || ext == "mp4") { return true }
        return false
    }
    
    //*****************************************//
    //    MARK: inner-class helper functions
    //*****************************************//
    private func arrayAcceptFilter(files: [URL], filter: MediaFilter) -> Bool{
        for file in files {
            if(self.fileAcceptFilter(file: file, filter: self.filter)){
                return true
            }
        }
        return false
    }
    
    private func fileAcceptFilter(file: URL, filter: MediaFilter) -> Bool{
        switch(filter){
            case .all: return true
            case .photos: return self.isPhoto(file: file)
            case .videos: return self.isVideo(file: file)
        }
    }
    
    private func loadSavedMedia(){
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        self.libraryURL = URL(string: paths)!.appendingPathComponent("Saved Media")
        if !FileManager.default.fileExists(atPath: self.libraryURL.path) {
            do {
                try FileManager.default.createDirectory(atPath: self.libraryURL.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
                return
            }
        }
        self.mediaSavable = true
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: self.libraryURL, includingPropertiesForKeys: nil)
            
            for fileURL in fileURLs {
                let fileExtension = fileURL.pathExtension.lowercased()
                switch fileExtension {
                    case "jpg","jpeg","rawdng", "mov", "mp4":
                        self.addToAlbum(file: fileURL)
                    default: continue
                }
            }
        } catch {
            CRFly.shared.viewController.showSimpleAlert(title: "Error Adding Media To Saved Album", msg: Text("Error loading files from Saved Media directory: " + String(describing: error)))
        }
    }
    
    private func createFileThumbnail(file: URL, appData: ApplicationData) -> any View {
        return ZStack {
            if(self.isVideo(file: file)){
                VideoThumbnailView(videoURL: file)
                    .foregroundColor(self.selectedItems.contains(file) ? .blue : .white)
                    .onTapGesture{ self.imgTapGesture(file: file, appData: appData) }
            } else {
                AsyncImage(url: file) { image in
                    image.image?.resizable().scaledToFill().frame(width: 140, height: 100).clipped()
                        .foregroundColor(self.selectedItems.contains(file) ? .blue : .white)
                        .onTapGesture{ self.imgTapGesture(file: file, appData: appData) }
                }
            }
            
            VStack {
                HStack {
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
                    else{ Image(systemName: "camera.metering.unknown").foregroundColor(.white) }
                    Spacer()
                }
            }
        }.frame(width: 140)
    }
    
    private func imgTapGesture(file: URL, appData: ApplicationData){
        if(!self.selectedItems.contains(file)){
            if(self.selectMode) { self.selectedItems.append(file) }
            else {
                CRFly.shared.viewController.displayView(view: AnyView(AlbumPreviewView(appData: appData, previewController: SavedAlbumPreviewController(albumController: self, file: file))), type: .albumMediaPreview, addToHistory: true)
            }
        } else {
            self.selectedItems.remove(at: self.selectedItems.firstIndex(of: file)!)
        }
    }
}
