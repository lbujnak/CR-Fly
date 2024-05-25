import SwiftUI

/// `AlbumController` defines essential methods and properties for its implementations, facilitating media loading into albums and generating displayable content within `AlbumView`. It plays a central role in media management across the application.
public protocol AlbumController {
    /// Provide a read-only access to the observable data class `AlbumData`, encapsulating details such as album content, settings, etc.
    var albumData: AlbumData { get }
    
    /// Provides a read-only unique identifier for the controller instance, generated upon initialization.
    var UUID: String { get }
    
    /// Returns unique identifier of concrete implementation of `AlbumController`.
    func getUniqueID() -> String
    
    /// Invoked when the album view appears on screen, triggering the loading of saved media.
    func appear()
    
    /// Invoked when the album view disappears from the screen, triggering the unloading of loaded media.
    func disappear()
    
    /// Executes necessary actions when the application transitions from background to foreground, such as reinitializing resources or updating the UI.
    func enterFromBackground()
    
    /// Prepares the application for transition to the background by saving state, pausing ongoing tasks, or securing sensitive information.
    func leaveToBackground()
    
    /// Toggles the selection mode on and off, clearing any selections when disabled.
    func toggleSelectMode()
    
    /// Applies a new filter to the album view, updating the visibility of media files based on the selected filter.
    func toggleFilter(newFilter: AlbumView.MediaFilter)
    
    /// Retrieves the current album mode.
    func getAlbumMode() -> AlbumView.AlbumMode
    
    /// Provides a UI view that displays the title of the current album mode.
    func getTitle() -> any View
    
    /// Returns the count of currently selected media items.
    func getSelectCount() -> Int
    
    /// Provides a UI view that displays the current selection status and total size of selected items.
    func getSelectStatus() -> any View
    
    /// Retrieves the UI content for the album based on the current filter and selection state.
    func getAlbumContent() -> any View
    
    /// Retrieves special buttons for the album view - used to draw unique content from concrete Album Controller.
    func getSpecialButtons() -> any View
    
    /// Selects all media items that match the current filter.
    func selectAll()
    
    /// Clears all selections in the current album.
    func unselectAll()
    
    /// Deletes selected media files.
    func trashSelected()
    
    /// Initiates the upload of selected media files to a designated location.
    func uploadSelected()
    
    /// Cleans up the album view.
    func cleanAlbum()
}

public extension AlbumController {
    func getUniqueID() -> String { UUID }
    func disappear() { albumData.selectMode = false }
    func enterFromBackground() { appear() }
    func leaveToBackground() { self.disappear() }
    func toggleFilter(newFilter: AlbumView.MediaFilter) { albumData.filter = newFilter }
    func getSpecialButtons() -> any View { EmptyView() }
}
