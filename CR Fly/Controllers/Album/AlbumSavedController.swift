import SwiftUI

/// `AlbumSavedController` is a concrete implementation of the `AlbumController` protocol tailored for managing media albums saved on the device. It provides functionality for media organization, selection, filtering, and various other media handling actions within the saved albums context.
public class AlbumSavedController: AlbumController {
    /// Reference to the `ViewController` responsible for managing navigation, presentation of different views within the application and displaying errors.
    private let viewController: ViewController
    
    /// Reference to an instance of `SceneController` that manages broader scene-related operations.
    private let sceneController: SceneController
    
    /// Reference to the observable data class `AlbumData`, encapsulating details such as album content, settings, etc.
    public let albumData = AlbumData()
    
    /// Reference to the observable data class `AlbumSavedData` unique for `AlbumSavedController` implementation.
    public let albumSavedData = AlbumSavedData()
    
    /// Reference to the observable data class `SceneData` containing scene's operational data.
    private var sceneData: SceneData
    
    /// Provides a read-only unique identifier for the controller instance, generated upon initialization.
    public let UUID = Foundation.UUID().uuidString
    
    /// Configuration for the UI grid that displays media items.
    private let columns = [GridItem(.adaptive(minimum: 140), alignment: .center)]
    
    /// Initializes a new instance of `AlbumSavedController`.
    public init(viewController: ViewController, sceneController: SceneController) {
        self.viewController = viewController
        self.sceneController = sceneController
        self.sceneData = sceneController.sceneData
        self.albumSavedData.savedMediaURL = DocURL(appDocDirPath: "Saved Media")
        
        if !self.albumSavedData.savedMediaURL!.existsItem() {
            do {
                try self.albumSavedData.savedMediaURL!.createItem(withIntermediateDirectories: true)
            } catch {
                self.albumSavedData.savedMediaURL = nil
                print("Load Save Media Error: \(error.localizedDescription)")
                return
            }
        }
        self.appear()
    }
    
    /// Invoked when the album view appears on screen, triggering the loading of saved media.
    public func appear() {
        self.loadSavedMedia()
    }
    
    /// Toggles the selection mode on and off, clearing any selections when disabled.
    public func toggleSelectMode() {
        self.albumData.selectMode.toggle()
        self.albumSavedData.selectedItems.removeAll()
    }
    
    /// Applies a new filter to the album view, updating the visibility of media files based on the selected filter.
    public func toggleFilter(newFilter: AlbumView.MediaFilter) {
        self.albumData.filter = newFilter
        for (_, files) in self.albumSavedData.albumItems {
            for file in files {
                if self.fileAcceptFilter(file: file, filter: self.albumData.filter) {
                    self.albumData.albumEmpty = false
                    return
                }
            }
        }
        self.albumData.albumEmpty = true
    }
    
    /// Returns the current mode of the album as `.saved`.
    public func getAlbumMode() -> AlbumView.AlbumMode { .saved }
    
    /// Provides a UI view that displays the title of the current album mode.
    public func getTitle() -> any View { Text("Saved") }
    
    /// Returns the count of currently selected media items.
    public func getSelectCount() -> Int { self.albumSavedData.selectedItems.count }
    
    /// Provides a UI view that displays the current selection status and total size of selected items.
    public func getSelectStatus() -> any View {
        if self.albumSavedData.selectedItems.count == 0 { return Text("Select Items") }
        else {
            var total: Int64 = 0
            for file in self.albumSavedData.selectedItems {
                do {
                    let fileAttributes = try file.getAttributesOfItem()
                    if let fileSize = fileAttributes[.size] as? NSNumber {
                        total += fileSize.int64Value
                    }
                } catch { continue }
            }
            return AlbumView.generateSelectText(totalBytes: total, itemCount: self.albumSavedData.selectedItems.count)
        }
    }
    
    /// Retrieves the UI content for the album based on the current filter and selection state.
    public func getAlbumContent() -> any View {
        ZStack {
            VStack {
                ForEach(self.albumSavedData.albumItems.sorted(by: { $0.key > $1.key }), id: \.key) { [self] date, files in
                    if self.arrayAcceptFilter(files: files, filter: self.albumData.filter) {
                        Section(header: HStack {
                            Text(date.description.prefix(10)).font(.custom("date", size: 15)).bold().padding(.top, 20.0).foregroundColor(.gray)
                            Spacer()
                        }) {
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
    }
    
    /// Selects all media items that match the current filter.
    public func selectAll() {
        self.albumSavedData.selectedItems = self.albumSavedData.albumItems.flatMap(\.value).filter {
            self.fileAcceptFilter(file: $0, filter: self.albumData.filter)
        }
    }
    
    /// Clears all selections in the current album.
    public func unselectAll() {
        self.albumSavedData.selectedItems.removeAll()
    }
    
    /// Moves selected media files to trash, effectively deleting them from the album.
    public func trashSelected() {
        self.trashFiles(files: self.albumSavedData.selectedItems)
        self.toggleSelectMode()
    }
    
    /// Initiates the upload of selected media files to a designated location.
    public func uploadSelected() {
        self.sceneController.uploadMedia(files: Set(self.albumSavedData.selectedItems), waitDownload: [])
        self.toggleSelectMode()
    }
    
    /// Cleans out all media items from the album, updating the view to reflect an empty state.
    public func cleanAlbum() {
        self.albumSavedData.albumItems.removeAll()
        self.albumData.albumEmpty = true
    }
    
    // MARK: Extension methods
    
    /// Adds a media files from image picker to album by copying file to app's saved media folder.
    public func saveImageFromPicker(data: Data) throws {
        if self.albumSavedData.savedMediaURL != nil {
            let fileName = Foundation.UUID().uuidString + ".jpg"
            let fileURL = self.albumSavedData.savedMediaURL!.appendFile(fileName: fileName)
            
            try data.write(to: fileURL.getURL())
            self.addToAlbum(file: fileURL)
        }
    }
    
    /// Adds a media file to the saved album if it isn't already present. This function checks the file's creation date and categorizes it under that date within the album. If an error occurs, it displays an alert with the error message.
    public func addToAlbum(file: DocURL) {
        if !file.isDirectory() {
            do {
                let attributes = try file.getAttributesOfItem()
                if let creationDate = attributes[.creationDate] as? Date {
                    let fileDate = SimpleDateFormatter().date(from: String(creationDate.description.prefix(10))) ?? Calendar.current.startOfDay(for: Date())
                    
                    if let _ = self.albumSavedData.albumItems[fileDate] {
                        if !self.albumSavedData.albumItems[fileDate]!.contains(file) {
                            self.albumSavedData.albumItems[fileDate]!.append(file)
                        }
                    } else {
                        self.albumSavedData.albumItems[fileDate] = [file]
                    }
                    
                    if self.albumData.albumEmpty { self.albumData.albumEmpty = false }
                }
            } catch {
                self.viewController.showSimpleAlert(title: "Error Adding Media To Saved Album", msg: Text("Error adding files to Saved Media Album: " + String(describing: error)))
            }
        }
    }
    
    /// Removes specified media files from the saved album and deletes them from the filesystem. If a file is not found in the album or an error occurs during deletion, an alert with the error message is displayed. Afterward, updates the album view based on the current filter.
    public func trashFiles(files: [DocURL]) {
        for file in files {
            do {
                let attributes = try file.getAttributesOfItem()
                if let creationDate = attributes[.creationDate] as? Date {
                    let fileDate = SimpleDateFormatter().date(from: String(creationDate.description.prefix(10)))!
                    
                    if let position = albumSavedData.albumItems[fileDate]?.firstIndex(of: file) {
                        self.albumSavedData.albumItems[fileDate]!.remove(at: position)
                        
                        if(self.albumSavedData.albumItems[fileDate]!.count == 0){
                            self.albumSavedData.albumItems.removeValue(forKey: fileDate)
                        }
                        
                        try file.removeItem()
                    }
                    else {
                        self.viewController.showSimpleAlert(title: "Error While Removing Saved Media", msg: Text("Trash request for file that is not in album!"))
                    }
                }
            } catch {
                self.toggleFilter(newFilter: self.albumData.filter)
                self.viewController.showSimpleAlert(title: "Error While Removing Saved Media", msg: Text("Saved media couldn't be removed!: " + String(describing: error)))
            }
        }
        self.toggleFilter(newFilter: self.albumData.filter)
    }
    
    /// Checks if a media file, specified by filename, is already saved in the album. Returns `true` if the file is present, otherwise `false`.
    public func isMediaSaved(fileName: String) -> Bool {
        return self.albumSavedData.albumItems.flatMap({ $0.value }).contains(where: { $0.getURL().lastPathComponent == fileName})
    }
    
    /// Determines whether a file is a photo based on its file extension. Supports JPG, JPEG, and RAWDNG formats.
    public func isPhoto(file: DocURL) -> Bool {
        let ext = file.getURL().pathExtension.lowercased()
        return ext == "jpg" || ext == "png" || ext == "jpeg" || ext == "rawdng" || ext == "heic"
    }
    
    /// Determines whether a file is a panoramic image based on its file extension. Supports PANO format.
    public func isPano(file: DocURL) -> Bool {
        return file.getURL().pathExtension.lowercased() == "pano"
    }
    
    /// Determines whether a file is a video based on its file extension. Supports MOV and MP4 formats.
    public func isVideo(file: DocURL) -> Bool {
        let ext = file.getURL().pathExtension.lowercased()
        return ext == "mov" || ext == "mp4"
    }
    
    /// Loads media from the device's document directory under 'Saved Media'. Filters and adds media to the album based on type. Handles errors by displaying an alert with the error message if media cannot be loaded.
    public func loadSavedMedia() {
        self.cleanAlbum()
        do {
            if self.albumSavedData.savedMediaURL == nil { throw URLError(.badURL) }
            
            let fileURLs = try self.albumSavedData.savedMediaURL!.getContentsOfDirectory()
            
            for fileURL in fileURLs {
                if !fileURL.getFileName().starts(with: "_tmp.") {
                    let fileExtension = fileURL.getFileNameExtension().lowercased()
                    switch fileExtension {
                    case "heic", "jpg", "jpeg", "rawdng", "mov", "mp4", "pano":
                        self.addToAlbum(file: fileURL)
                    default: continue
                    }
                }
            }
        } catch {
            self.viewController.showSimpleAlert(title: "Error Adding Media To Saved Album", msg: Text("Error loading files from Saved Media directory: " + String(describing: error)))
        }
    }
    
    // MARK: Helper Functions
    
    /// Evaluates an array of files to determine if at least one file meets the criteria specified by the current filter setting. Returns `true` if at least one file matches the filter, otherwise `false`.
    private func arrayAcceptFilter(files: [DocURL], filter: AlbumView.MediaFilter) -> Bool {
        return files.contains { file in
            self.fileAcceptFilter(file: file, filter: self.albumData.filter)
        }
    }
    
    /// Checks if a single file meets the criteria of the specified media filter (e.g., all, photos, videos). Utilizes helper functions to determine the file type.
    private func fileAcceptFilter(file: DocURL, filter: AlbumView.MediaFilter) -> Bool {
        switch filter {
        case .all: true
        case .photos: self.isPhoto(file: file)
        case .videos: self.isVideo(file: file)
        }
    }
    
    /// Creates and returns a thumbnail view for a specific media file. This view changes appearance based on whether the file is selected or being uploaded. It also includes interaction gestures like tap to handle file selection or preview.
    private func createFileThumbnail(file: DocURL) -> any View {
        ZStack {
            if self.isVideo(file: file) {
                VideoThumbnailView(videoURL: file).foregroundColor(self.albumSavedData.selectedItems.contains(file) ? .blue : .white)
                    .onTapGesture {
                        self.imgTapGesture(file: file)
                    }
            } else {
                ImageThumbnailView(url: file).frame(width: 140, height: 100).clipped()
                    .foregroundColor(self.albumSavedData.selectedItems.contains(file) ? .blue : .white)
                    .onTapGesture {
                        self.imgTapGesture(file: file)
                    }
            }
            
            VStack {
                HStack {
                    Spacer()
                    if self.albumData.selectMode {
                        Image(systemName: self.albumSavedData.selectedItems.contains(file) ? "checkmark.square.fill" : "square").foregroundColor(self.albumSavedData.selectedItems.contains(file) ? .blue : .white).padding([.trailing, .top], 4).font(.custom("checkbox", size: 15))
                    }
                }
                
                Spacer()
                HStack {
                    if self.isVideo(file: file) {
                        Image(systemName: "video.fill").foregroundColor(.white).padding([.leading, .bottom], 4).font(.custom("fileType", size: 15))
                    } else if self.isPhoto(file: file) {
                        Image(systemName: "photo.fill").foregroundColor(.white).padding([.leading, .bottom], 4).font(.custom("fileType", size: 15))
                    } else if self.isPano(file: file) {
                        Image(systemName: "pano.fill").foregroundColor(.white).padding([.leading, .bottom], 4).font(.custom("fileType", size: 15))
                    } else {
                        Image(systemName: "camera.metering.unknown").foregroundColor(.white)
                    }
                    Spacer()
                    
                    if self.sceneData.openedProject.readyToUpload, self.albumSavedData.savedMediaURL != nil {
                        let uploading = self.sceneData.mediaUploadState?.uploadSet.contains(where: { $0.getFileNameWithout(prefix: "_tmp.") == file.getFileName()}) ?? false
                        
                        if !self.sceneData.openedProject.fileList.contains(file.getFileName()) {
                            Image(systemName: "square.and.arrow.up.fill").foregroundColor(uploading ? .blue : .white)
                                .padding([.trailing, .bottom], 4).font(.custom("dwnld", size: 15))
                        }
                    }
                }
            }
        }.frame(width: 140)
    }
    
    /// Handles tap gestures on a media file thumbnail. Toggles the file's selection status within the album or initiates a preview, depending on the current mode of the album.
    private func imgTapGesture(file: DocURL) {
        if !self.albumSavedData.selectedItems.contains(file) {
            if self.albumData.selectMode {
                self.albumSavedData.selectedItems.append(file)
            } else {
                self.albumData.albumPreviewController = AlbumSavedPreviewController(file: file, albumSavedController: self, sceneController: self.sceneController)
                self.albumData.albumPreviewController!.appear()
            }
        } else {
            self.albumSavedData.selectedItems.remove(at: self.albumSavedData.selectedItems.firstIndex(of: file)!)
        }
    }
}
