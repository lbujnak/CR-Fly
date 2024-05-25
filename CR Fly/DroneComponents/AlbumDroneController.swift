import DJISDK
import SwiftUI

///`AlbumDroneController` is a concrete implementation of the `AlbumController` protocol tailored for managing media in drone's album. It provides functionality for media organization, selection, filtering, and various other media handling actions within the drone's albums context.
public class AlbumDroneController: AlbumController {
    /// Reference to the `ViewController` responsible for managing navigation, presentation of different views within the application and displaying errors.
    private let viewController: ViewController
    
    /// Reference to an instance of `DJIDroneController` that facilitates communication and control of the DJI drone.
    private let droneController: DJIDroneController
    
    /// Reference to an instance of `SceneController` that manages broader scene-related operations.
    private let sceneController: SceneController
    
    /// Reference to an instance of `AlbumSavedController` that manages the overall album of saved media.
    private let albumSavedController: AlbumSavedController
    
    /// Reference to the observable data class `DroneData` containing drone's operational data.
    private let droneData: DroneData
    
    /// Reference to the observable data class `SceneData` containing scene's operational data.
    private let sceneData: SceneData
    
    /// Reference to the observable data class `DJIDroneData` containing DJI drone's operational data.
    private let djiDroneData: DJIDroneData
    
    /// Reference to the observable data class `AlbumSavedData` unique for `AlbumSavedController` implementation.
    private let albumSavedData: AlbumSavedData
    
    /// Reference to the observable data class `AlbumData`, encapsulating details such as album content, settings, etc.
    public let albumData = AlbumData()
    
    /// Reference to the observable data class `AlbumDroneData` unique for `AlbumDroneController` implementation.
    public let albumDroneData = AlbumDroneData()
    
    /// Provides a read-only unique identifier for the controller instance, generated upon initialization.
    public let UUID = Foundation.UUID().uuidString
    
    /// Configuration for the UI grid that displays media items.
    private let columns = [GridItem(.adaptive(minimum: 140), alignment: .center)]
    
    /// Initializes a new instance of the `AlbumDroneController` class. This controller is responsible for managing drone-specific album operations, such as media fetching, uploading, and deletion.
    public init(viewController: ViewController, droneController: DJIDroneController, sceneController: SceneController, albumSavedController: AlbumSavedController) {
        self.viewController = viewController
        self.droneController = droneController
        self.sceneController = sceneController
        self.albumSavedController = albumSavedController
        
        self.droneData = droneController.droneData
        self.sceneData = sceneController.sceneData
        self.djiDroneData = droneController.djiDroneData
        self.albumSavedData = albumSavedController.albumSavedData
    }
    
    /// Invoked when the album view appears on screen, triggering the loading of saved media.
    public func appear() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            if self.droneData.deviceConnected {
                self.droneController.pushCommand(command: EnterDroneAlbum())
            }
        }
    }
    
    public func disappear() {
        self.cleanAlbum()
    }
    
    /// Toggles the selection mode on and off, clearing any selections when disabled.
    public func toggleSelectMode() {
        self.albumData.selectMode.toggle()
        self.albumDroneData.selectedItems.removeAll()
    }
    
    /// Applies a new filter to the album view, updating the visibility of media files based on the selected filter.
    public func toggleFilter(newFilter: AlbumView.MediaFilter) {
        self.albumData.filter = newFilter
        for (_, files) in self.albumDroneData.albumItems {
            for file in files {
                if fileAcceptFilter(file: file, filter: self.albumData.filter) {
                    self.albumData.albumEmpty = false
                    return
                }
            }
        }
        self.albumData.albumEmpty = true
    }
    
    /// Retrieves the current album mode.
    public func getAlbumMode() -> AlbumView.AlbumMode { .drone }
    
    /// Provides a UI view that displays the title of the current album mode.
    public func getTitle() -> any View {
        HStack {
            Image(systemName: "app.connected.to.app.below.fill")
            Text(self.djiDroneData.device != nil && self.djiDroneData.device!.model != nil ? self.djiDroneData.device!.model! : "Aircraft Album")
        }
    }
    
    /// Returns the count of currently selected media items.
    public func getSelectCount() -> Int { self.albumDroneData.selectedItems.count }
    
    /// Provides a UI view that displays the current selection status and total size of selected items.
    public func getSelectStatus() -> any View {
        if self.albumDroneData.selectedItems.count == 0 { return Text("Select Items") }
        else {
            var total: Int64 = 0
            for obj in self.albumDroneData.selectedItems {
                total += obj.fileSizeInBytes
            }
            return AlbumView.generateSelectText(totalBytes: total, itemCount: self.albumDroneData.selectedItems.count)
        }
    }
    
    /// Retrieves the UI content for the album based on the current filter and selection state.
    public func getAlbumContent() -> any View {
        VStack {
            ForEach(self.albumDroneData.albumItems.sorted(by: { $0.key > $1.key }), id: \.key) { [self] date, files in
                if arrayAcceptFilter(files: files, filter: self.albumData.filter) {
                    Section(header:
                                HStack {
                        Text(date.description.prefix(10)).font(.custom("date", size: 15)).bold().padding(.top, 20.0).foregroundColor(.gray)
                        Spacer()
                    }
                    ) {
                        LazyVGrid(columns: self.columns, spacing: 5) {
                            ForEach(files, id: \.self) { file in
                                if self.fileAcceptFilter(file: file, filter: self.albumData.filter) {
                                    AnyView(self.createFileThumbnail(file: file))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Retrieves special buttons for the album view - used to draw unique content from concrete Album Controller.
    public func getSpecialButtons() -> any View {
        Group {
            if self.albumSavedData.savedMediaURL != nil {
                let dwnldDisabled = self.getSelectCount() == 0
                
                Image(systemName: "tray.and.arrow.down").foregroundColor(dwnldDisabled ? .secondary : .primary)
                    .onTapGesture {
                        self.saveFiles(files: Set(self.albumDroneData.selectedItems))
                        self.toggleSelectMode()
                    }.disabled(dwnldDisabled)
            }
        }
    }
    
    /// Selects all media items that match the current filter.
    public func selectAll() {
        self.albumDroneData.selectedItems = self.albumDroneData.albumItems.flatMap(\.value).filter { self.fileAcceptFilter(file: $0, filter: self.albumData.filter) }
    }
    
    /// Clears all selections in the current album.
    public func unselectAll() { self.albumDroneData.selectedItems.removeAll() }
    
    /// Deletes selected media files.
    public func trashSelected() {
        trashFiles(files: self.albumDroneData.selectedItems)
        self.toggleSelectMode()
    }
    
    /// Initiates the upload of selected media files to a designated location.
    public func uploadSelected() {
        self.droneController.uploadFiles(files: Set(self.albumDroneData.selectedItems))
        self.toggleSelectMode()
    }
    
    /// Cleans up the album view.
    public func cleanAlbum() {
        self.albumDroneData.albumItems.removeAll()
        self.albumData.albumEmpty = true
    }

    /// Adds an array of `DJIMediaFile` to the album if they aren't already present.
    func addToAlbum(files: [DJIMediaFile]) {
        for file in files {
            let fileDateString = String(file.timeCreated.prefix(10))
            let fileDate = SimpleDateFormatter().date(from: fileDateString)!
            
            if let _ = albumDroneData.albumItems[fileDate] {
                self.albumDroneData.albumItems[fileDate]!.append(file)
            } else {
                self.albumDroneData.albumItems[fileDate] = [file]
            }
            
            if self.albumData.albumEmpty, self.fileAcceptFilter(file: file, filter: self.albumData.filter) {
                self.albumData.albumEmpty = false
            }
            self.albumData.albumLoading = false
        }
    }
    
    /// Saves media files to the local storage from the drone.
    func saveFiles(files: Set<DJIMediaFile>) {
        self.droneController.pushCommand(command: StartDroneMediaDownload(files: files))
    }
    
    /// Deletes specified files from the drone.
    func trashFiles(files: [DJIMediaFile]) {
        self.droneController.pushCommand(command: RemoveDroneMedia(files: files))
        self.toggleFilter(newFilter: self.albumData.filter)
    }
    
    /// Checks if a media file is already saved in the drone's album.
    func isMediaSaved(file: DJIMediaFile) -> Bool {
        self.albumSavedController.isMediaSaved(fileName: file.fileName)
    }
    
    /// Determines if a given file is a photo.
    func isPhoto(file: DJIMediaFile) -> Bool {
        if file.mediaType == DJIMediaType.JPEG || file.mediaType == DJIMediaType.RAWDNG { return true }
        return false
    }
    
    /// Checks if the file is a panoramic image.
    func isPano(file: DJIMediaFile) -> Bool {
        if file.mediaType == DJIMediaType.panorama { return true }
        return false
    }
    
    /// Identifies if the file is a video.
    func isVideo(file: DJIMediaFile) -> Bool {
        if file.mediaType == DJIMediaType.MOV || file.mediaType == DJIMediaType.MP4 { return true }
        return false
    }
    
    // MARK: Helper Functions
    
    /// Evaluates an array of files to determine if at least one file meets the criteria specified by the current filter setting. Returns `true` if at least one file matches the filter, otherwise `false`.
    private func arrayAcceptFilter(files: [DJIMediaFile], filter: AlbumView.MediaFilter) -> Bool {
        for file in files {
            if self.fileAcceptFilter(file: file, filter: self.albumData.filter) {
                return true
            }
        }
        return false
    }
    
    /// Checks if a single file meets the criteria of the specified media filter (e.g., all, photos, videos). Utilizes helper functions to determine the file type.
    private func fileAcceptFilter(file: DJIMediaFile, filter: AlbumView.MediaFilter) -> Bool {
        switch filter {
        case .all: true
        case .photos: self.isPano(file: file) || self.isPhoto(file: file)
        case .videos: self.isVideo(file: file)
        }
    }
    
    /// Creates and returns a thumbnail view for a specific media file. This view changes appearance based on whether the file is selected or being uploaded. It also includes interaction gestures like tap to handle file selection or preview.
    private func createFileThumbnail(file: DJIMediaFile) -> any View {
        ZStack {
            if file.thumbnail != nil, self.albumDroneData.showingThumbnail.contains(file) {
                Image(uiImage: file.thumbnail!)
                    .resizable().scaledToFill().frame(width: 140, height: 100).clipped()
                    .foregroundColor(self.albumDroneData.selectedItems.contains(file) ? .blue : .white)
            } else {
                ProgressView().frame(width: 140, height: 100)
            }
            VStack {
                HStack {
                    if !self.isMediaSaved(file: file) {
                        let downloading = self.droneData.mediaDownloadState?.downloadSet.contains(file) ?? false
                        Image(systemName: "tray.and.arrow.down.fill").foregroundColor(downloading ? .blue : .white).padding([.trailing, .top], 4).font(.custom("dwnld", size: 15))
                    }
                    
                    Spacer()
                    if self.albumData.selectMode {
                        Image(systemName: self.albumDroneData.selectedItems.contains(file) ? "checkmark.square.fill" : "square").foregroundColor(self.albumDroneData.selectedItems.contains(file) ? .blue : .white).padding([.trailing, .top], 4).font(.custom("checkbox", size: 15))
                    }
                }
                
                Spacer()
                HStack {
                    if self.isVideo(file: file) { Image(systemName: "video.fill").foregroundColor(.white).padding([.leading, .bottom], 4).font(.custom("fileType", size: 15)) }
                    else if self.isPhoto(file: file) { Image(systemName: "photo.fill").foregroundColor(.white).padding([.leading, .bottom], 4).font(.custom("fileType", size: 15)) }
                    else if self.isPano(file: file) { Image(systemName: "pano.fill").foregroundColor(.white).padding([.leading, .bottom], 4).font(.custom("fileType", size: 15)) }
                    else { Image(systemName: "camera.metering.unknown").foregroundColor(.white) }
                    Spacer()
                    
                    if self.sceneData.openedProject.readyToUpload, self.albumSavedData.savedMediaURL != nil {
                        let uploading = self.sceneData.mediaUploadState?.uploadSet.contains(where: { $0.getFileNameWithout(prefix: "_tmp.") == file.fileName}) ?? false || self.sceneData.mediaUploadState?.waitDownload.contains(where: { $0.fileName == file.fileName }) ?? false
                        
                        if !self.sceneData.openedProject.fileList.contains(file.fileName) {
                            Image(systemName: "square.and.arrow.up.fill").foregroundColor(uploading ? .blue : .white)
                                .padding([.trailing, .bottom], 4).font(.custom("dwnld", size: 15))
                        }
                    }
                }
            }
        }.frame(width: 140)
            .onTapGesture {
                if !self.albumDroneData.selectedItems.contains(file) {
                    if self.albumData.selectMode { self.albumDroneData.selectedItems.append(file) }
                    else {
                        if (self.isVideo(file: file) && file.durationInSeconds > 1) || !self.isVideo(file: file) {
                            self.albumData.albumPreviewController = AlbumDronePreviewController(file: file)
                            self.albumData.albumPreviewController!.appear()
                        } else {
                            self.viewController.showSimpleAlert(title: "Error Opening Video Playback", msg: Text("Video could not be played, because it is too short."))
                        }
                    }
                } else {
                    self.albumDroneData.selectedItems.remove(at: self.albumDroneData.selectedItems.firstIndex(of: file)!)
                }
            }
            .onAppear(){
                self.albumDroneData.showingThumbnail.insert(file)
                if file.thumbnail == nil {
                    self.droneController.pushCommand(command: FetchDroneThumbnail(file: file))
                }
            }
    }
}
