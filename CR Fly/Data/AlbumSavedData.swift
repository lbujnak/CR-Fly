import Foundation

/// `AlbumSavedData` is an observable data model class that manages the storage, selection, and organization of media files within an album. It maintains a structure for saved media items, handles selections for operations like delete or share, and tracks the location of saved media files on the device.
public class AlbumSavedData: ObservableObject {
    /// A dictionary that maps dates to arrays of `DocURL` objects, representing media files saved under specific dates. This organizational method helps in grouping media by date for display in the UI.
    @Published var albumItems: [Date: [DocURL]] = [:]
    
    /// An array of `DocURL` objects that represent the currently selected media items in the album. This allows for operations on multiple items, such as batch deletion or sharing.
    @Published var selectedItems: [DocURL] = []
    
    /// An optional `DocURL` that points to the location where the media files are stored on the device. This is used to retrieve and manage files within the filesystem.
    @Published var savedMediaURL: DocURL? = nil
}
