import Foundation

/// `AlbumData` is an observable data model class that manages state related to album functionalities within an application. It tracks various properties that control the behavior and appearance of album-related views, responding to user interactions and data changes.
public class AlbumData: ObservableObject {
    /// A boolean that indicates whether the album currently has any media items. This is used to control view states such as showing empty state messages or content.
    @Published var albumEmpty: Bool = true
    
    ///  A boolean that represents whether the album is in the process of loading its contents. Useful for showing loading indicators in the UI during data fetch operations.
    @Published var albumLoading: Bool = false
    
    /// An optional `AlbumPreviewController` that manages the preview of selected media items. When set, it typically triggers a transition to a detailed preview view.
    @Published var albumPreviewController: AlbumPreviewController? = nil
    
    /// A boolean that toggles the selection mode in the album view, allowing users to select one or more items for actions such as deleting or sharing.
    @Published var selectMode: Bool = false
    
    /// An enum of type `AlbumView.MediaFilter` that indicates the current filter applied to the album view, such as showing all items, only photos, or only videos.
    @Published var filter: AlbumView.MediaFilter = .all
}
