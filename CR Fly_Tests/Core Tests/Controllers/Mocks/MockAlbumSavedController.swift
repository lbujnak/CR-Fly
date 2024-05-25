import XCTest
@testable import CR_Fly

final class MockAlbumSavedController: AlbumSavedController {
    var recentlyTrashed : [DocURL] = []
    
    override func trashFiles(files: [DocURL]) {
        recentlyTrashed = files
    }
}
