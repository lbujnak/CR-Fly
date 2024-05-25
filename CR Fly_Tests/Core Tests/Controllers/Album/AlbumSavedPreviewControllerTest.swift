import XCTest
import SwiftUI
@testable import CR_Fly
import ViewInspector

final class AlbumSavedPreviewControllerTests: XCTestCase {
    
    var previewController: AlbumSavedPreviewController!
    var mockAlbumSavedController: MockAlbumSavedController!
    var mockViewController: MockViewController!
    var mockSceneController: MockSceneController!
    var mockFileURL: DocURL!
    
    override func setUp() {
        mockViewController = MockViewController()
        mockSceneController = MockSceneController(viewController: mockViewController)
        mockAlbumSavedController = MockAlbumSavedController(viewController: mockViewController, sceneController: mockSceneController)
        mockFileURL = DocURL(dirURL: URL(string: "/dummy/file4.mp4")!)
        previewController = AlbumSavedPreviewController(file: mockFileURL, albumSavedController: mockAlbumSavedController, sceneController: mockSceneController)
        mockAlbumSavedController.albumData.albumPreviewController = previewController
        XCTAssertNotNil(mockAlbumSavedController.albumData.albumPreviewController)
        previewController.appear()
    }
    
    override func tearDown() {
        previewController.disappear()
        XCTAssertNil(mockAlbumSavedController.albumData.albumPreviewController)
        mockViewController = nil
        mockSceneController = nil
        mockAlbumSavedController = nil
        previewController = nil
        super.tearDown()
    }

    func testGetPreviewableContent() throws {
        previewController.albumPreviewData.isShowingVideo = true
        XCTAssertNoThrow(try previewController.getPreviewableContent().inspect().find(AlbumSavedPreviewController.SavedVideoPlayer.self))

        previewController.albumPreviewData.isShowingVideo = false
        XCTAssertNoThrow(try previewController.getPreviewableContent().inspect().find(ViewInspector.ViewType.AsyncImage.self))
    }
    
    func testResumePauseSliderUploadTrash() {
        previewController.pauseVideo()
        XCTAssertFalse(previewController.albumPreviewData.isPlayingVideo)
        
        previewController.resumeVideo()
        XCTAssertTrue(previewController.albumPreviewData.isPlayingVideo)
        
        previewController.albumPreviewData.videoCurrentTime = 10
        previewController.sliderEditingChanged(action: false)
        
        previewController.trashFile()
        XCTAssertEqual(mockAlbumSavedController.recentlyTrashed.count, 1)
        XCTAssertTrue(mockAlbumSavedController.recentlyTrashed.contains(mockFileURL))
        
        previewController.uploadFile()
        XCTAssertEqual(mockSceneController.lastUploadRequest.count, 1)
        XCTAssertTrue(mockSceneController.lastUploadRequest.contains(mockFileURL))
    }
}
