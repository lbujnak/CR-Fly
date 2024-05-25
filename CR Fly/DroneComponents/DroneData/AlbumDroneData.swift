import DJISDK
import Foundation

/**
 `AlbumDroneData` is a class that acts as an observable object within SwiftUI, managing the state of media files captured by DJI drones. It tracks and updates the UI components based on changes to drone media, such as selection states and media availability.
 
 - The class is typically used within a SwiftUI view model to bind UI components to the underlying drone media data, allowing for reactive updates when changes occur.
 */
public class AlbumDroneData: ObservableObject {
    /// An array of `DJIMediaFile` objects that represent the currently selected media files in the user interface. This allows for operations such as deletion or sharing on the selected files.
    @Published var selectedItems: [DJIMediaFile] = []
    
    /// A set of `DJIMediaFile` objects representing the media files for which thumbnails are currently being shown.
    @Published var showingThumbnail: Set<DJIMediaFile> = []
    
    /// A dictionary that organizes media files by their capture dates. Each key is a `Date` object representing the day the media was captured, and the value is an array of `DJIMediaFile` objects corresponding to that date. This structure aids in displaying media chronologically.
    @Published var albumItems: [Date: [DJIMediaFile]] = [:]
    
    /// A boolean that indicates whether the preview images for the media files are currently being fetched. This is useful for showing loading indicators in the UI while previews are being prepared.
    @Published var previewFetching: Bool = false
}
