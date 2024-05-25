import PhotosUI
import SwiftUI

/// `AlbumView` provides a user interface for viewing and interacting with a collection of media files, such as photos and videos, stored either in `AlbumController`. It supports various functionalities including media filtering, selection for operations, and switching between different album modes.
public struct AlbumView: AppearableView {
    /// Defines the modes in which an album can operate, typically to distinguish between different sources or types of media collections.
    public enum AlbumMode {
        /// Represents albums that consist of media collected from drone flights, usually involving aerial or geographic data.
        case drone
        
        /// Pertains to albums that are curated or saved by users, potentially including imported or manually selected media.
        case saved
    }
    
    /// Represents the filters that can be applied to an album to narrow down the displayed media based on their type.
    public enum MediaFilter {
        /// No filtering is applied, and all media types are shown.
        case all
        
        /// Only photographic content is displayed, filtering out other media types like videos.
        case photos
        
        /// Only video content is shown, excluding photos and other non-video media.
        case videos
    }
    
    /// Reference to the `ViewController` responsible for managing navigation, presentation of different views within the application and displaying errors.
    private let viewController: ViewController
    
    /// Reference to an instance of `AlbumDroneController` that manages the overall album of drone's media.
    private let albumDroneController: AlbumDroneController
    
    /// Reference to an instance of `AlbumSavedController` that manages the overall album of saved media.
    private let albumSavedController: AlbumSavedController
    
    /// Recerence to the `AlbumController` for specific `AlbumMode`.
    private let controller: any AlbumController
    
    /// Reference to the observable data class `SceneData` containing scene's operational data.
    @ObservedObject private var sceneData: SceneData
    
    /// Reference to the observable data class `DroneData` containing drone's operational data.
    @ObservedObject private var droneData: DroneData
    
    /// Reference to the observable data class `AlbumSavedData` unique for `AlbumSavedController` implementation.
    @ObservedObject private var albumSavedData: AlbumSavedData
    
    /// Reference to the observable data class `AlbumDroneData` unique for `AlbumDroneController` implementation.
    @ObservedObject private var albumDroneData: AlbumDroneData
    
    /// Reference to the observable data class `AlbumData`, encapsulating details such as album content, settings, etc.
    @ObservedObject private var albumData: AlbumData
    
    /// Defines the modes in which an album can operate.
    @State private var albumMode: AlbumMode
    
    /// Array of selected items in PhotoPicker.
    @State private var selectedItems = [PhotosPickerItem]()
    
    /// Array of selected images in PhotoPicker.
    @State private var selectedImages = [Image]()
    
    /// Initializes the `AlbumView`.
    public init(albumMode: AlbumMode, viewController: ViewController, sceneData: SceneData, droneData: DroneData, albumSavedController: AlbumSavedController, albumDroneController: AlbumDroneController) {
        self.albumMode = albumMode
        self.sceneData = sceneData
        self.droneData = droneData
        self.albumSavedData = albumSavedController.albumSavedData
        self.albumDroneData = albumDroneController.albumDroneData
        
        self.viewController = viewController
        self.albumSavedController = albumSavedController
        self.albumDroneController = albumDroneController
        
        switch albumMode {
        case .drone:
            self.controller = albumDroneController
            self.albumData = albumDroneController.albumData
        case .saved:
            self.controller = albumSavedController
            self.albumData = albumSavedController.albumData
        }
    }
    
    /// Called when the object becomes visible within the user interface.
    public func appear() {
        self.controller.appear()
    }
    
    /// Called when the object is no longer visible within the user interface.
    public func disappear() {
        self.controller.disappear()
    }
    
    /// Constructs the body of the `AlbumView`, which includes dynamic view components based on the state of the album data and user interactions.
    public var body: some View {
        if self.albumData.albumPreviewController != nil {
            // Dispplay AlbumPreviewView if preview is active
            AlbumPreviewView(previewController: self.albumData.albumPreviewController!, sceneData: self.sceneData)
        } else {
            VStack {
                HideableTopBarView(topBar: {
                    VStack(spacing: 10) {
                        HStack(spacing: 30) {
                            // MARK: TopBar
                            if !self.albumData.selectMode {
                                Button("←") {
                                    self.viewController.displayPreviousView()
                                }.foregroundColor(.primary).font(.largeTitle)
                                
                                Spacer()
                                HStack {
                                    // MARK: Construct button for every album
                                    ForEach(0 ..< 2) { index in
                                        let controller: AlbumController = index == 0 ? self.albumDroneController : self.albumSavedController
                                        
                                        let showing = self.controller.getUniqueID() == controller.getUniqueID()
                                        Button {
                                            self.albumMode = controller is AlbumSavedController ? .saved : .drone
                                            self.viewController.addView(type: .albumView, view: AlbumView(albumMode: self.albumMode, viewController: self.viewController, sceneData: self.sceneData, droneData: self.droneData, albumSavedController: self.albumSavedController, albumDroneController: self.albumDroneController))
                                            self.viewController.displayView(type: .albumView, addPreviousToHistory: false)
                                        } label: {
                                            AnyView(controller.getTitle())
                                        }.foregroundColor(showing ? .primary : .secondary).disabled(showing)
                                    }.padding([.leading, .trailing], 10)
                                }.padding(.leading, self.albumMode == .saved ? 67 : 0)
                                
                                Spacer()
                                if self.albumMode == .saved {
                                    PhotosPicker(selection: self.$selectedItems, matching: .images) {
                                        Image(systemName: "plus.square").font(Font.system(.title)).foregroundColor(self.albumSavedData.savedMediaURL != nil ? .primary : .secondary)
                                    }
                                    .onChange(of: self.selectedItems) {
                                        Task {
                                            for item in self.selectedItems {
                                                if let imageData = try? await item.loadTransferable(type: Data.self) {
                                                    do {
                                                        try (self.controller as! AlbumSavedController).saveImageFromPicker(data: imageData)
                                                    } catch {
                                                        DispatchQueue.main.async {
                                                            self.viewController.showSimpleAlert(title: "Error Adding Media To Saved Album", msg: Text("Media could not be transfered to app's directory. Error: \(error.localizedDescription)"))
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }.padding(.trailing, 5)
                                }
                                
                                Image(systemName: "cursorarrow.square").font(Font.system(.title)).onTapGesture {
                                    self.controller.toggleSelectMode()
                                }
                            } else {
                                Spacer()
                                HStack {
                                    AnyView(self.controller.getSelectStatus())
                                }.padding([.leading], 40)
                                
                                Spacer()
                                Image(systemName: "cursorarrow.square.fill").foregroundColor(.blue).font(Font.system(.title)).onTapGesture {
                                    self.controller.toggleSelectMode()
                                }
                            }
                        }.frame(height: 50).background(Color(UIColor.secondarySystemBackground))
                        
                        // MARK: Album filter
                        HStack(alignment: .center) {
                            HStack(alignment: .center, spacing: 100) {
                                Button { self.controller.toggleFilter(newFilter: MediaFilter.all) }
                            label: { Text("All").foregroundColor(self.albumData.filter == .all ? Color.primary : Color.secondary) }
                                
                                Button { self.controller.toggleFilter(newFilter: MediaFilter.photos) }
                            label: { Text("Photos").foregroundColor(self.albumData.filter == .photos ? Color.primary : Color.secondary) }
                                
                                Button { self.controller.toggleFilter(newFilter: MediaFilter.videos) }
                            label: { Text("Videos").foregroundColor(self.albumData.filter == .videos ? Color.primary : Color.secondary) }
                            }.padding([.horizontal], 100)
                        }.frame(height: 40).background(Color(UIColor.secondarySystemBackground)).cornerRadius(10)
                    }
                }, content: {
                    // MARK: Content of album
                    if self.albumData.albumEmpty {
                        Spacer()
                        if self.albumData.albumLoading {
                            ProgressView().scaleEffect(x: 2, y: 2, anchor: .center).progressViewStyle(CircularProgressViewStyle(tint: .primary))
                        } else {
                            Image(systemName: "photo.fill").foregroundColor(.gray).font(.custom("Photo icon", fixedSize: 80))
                            Text("No Photos or Videos").foregroundColor(.gray).padding([.top], 20)
                        }
                        Spacer()
                    } else {
                        AnyView(self.controller.getAlbumContent())
                    }
                }, scrollable: self.albumData.albumEmpty ? false : true, scrollStartAt: self.albumData.albumEmpty ? 0 : 100)
                
                // MARK: Bottom bar
                if self.albumData.selectMode {
                    HStack(spacing: 50) {
                        let emptySelect = self.controller.getSelectCount() == 0
                        
                        Image(systemName: "trash").foregroundColor(emptySelect ? .secondary : .primary).onTapGesture {
                            self.controller.trashSelected()
                        }.disabled(emptySelect)
                        
                        Spacer()
                        Button("Clear") {
                            self.controller.unselectAll()
                        }.foregroundColor(emptySelect ? .secondary : .primary).disabled(emptySelect)
                        
                        Spacer()
                        Button("Select All") {
                            self.controller.selectAll()
                        }.foregroundColor(.primary)
                        
                        Spacer()
                        AnyView(self.controller.getSpecialButtons())
                        
                        if self.albumSavedData.savedMediaURL != nil {
                            let uploadDisabled = emptySelect || (!self.sceneData.openedProject.readyToUpload)
                            
                            Image(systemName: "square.and.arrow.up").foregroundColor(uploadDisabled ? .secondary : .primary).onTapGesture {
                                self.controller.uploadSelected()
                            }.disabled(uploadDisabled)
                        }
                    }.frame(height: 40).background(Color(UIColor.secondarySystemBackground).ignoresSafeArea()).foregroundColor(.gray)
                }
            }
        }
    }
    
    /// Generates a textual representation of the number of selected files and their total size, formatted in a user-friendly way.
    public static func generateSelectText(totalBytes: Int64, itemCount: Int) -> Text {
        if totalBytes >= 1_000_000_000 {
            Text("\(itemCount) file(s) selected (\(String(format: "%.2f", Double(totalBytes / 1_000_000_000))) GB)")
        } else if totalBytes >= 1_000_000 {
            Text("\(itemCount) file(s) selected (\(String(format: "%.2f", Double(totalBytes / 1_000_000))) MB)")
        } else if totalBytes >= 1_000 {
            Text("\(itemCount) file(s) selected (\(String(format: "%.2f", Double(totalBytes / 1_000))) kB)")
        } else {
            Text("\(itemCount) file(s) selected (\(String(format: "%.2f", Double(totalBytes))) B)")
        }
    }
}
