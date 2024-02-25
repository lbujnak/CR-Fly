import SwiftUI

public enum MediaFilter {
    case all
    case photos
    case videos
}

public class AlbumController: ObservableObject, Identifiable {
    
    @Published var selectMode: Bool
    @Published var filter: MediaFilter = .all
    @Published var albumEmpty: Bool = true
    @Published var albumLoading: Bool = false
    
    init(){
        self.selectMode = false
    }
    
    public func appear() { }
    public func disappear() {
        self.selectMode = false
    }
    public func toggleSelectMode() { self.selectMode.toggle() }
    public func toggleFilter(newFilter: MediaFilter) { return }
    
    public func getTitle(appData: ApplicationData) -> any View { return EmptyView() }
    public func getSelectCount() -> Int { return 0 }
    public func getSelectStatus() -> any View { return EmptyView() }
    public func getAlbumContent(appData: ApplicationData) -> any View { return EmptyView() }
    public func getSpecialButtons(appData: ApplicationData) -> any View { return EmptyView() }
    
    public func selectAll() { return }
    public func unselectAll() { return }
    public func trashSelected() { return }
    public func uploadSelected() { return }
}
