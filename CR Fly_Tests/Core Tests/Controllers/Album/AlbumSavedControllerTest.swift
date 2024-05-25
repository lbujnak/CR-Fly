import XCTest
import SwiftUI
@testable import CR_Fly
import ViewInspector

final class AlbumSavedControllerTests: XCTestCase {

    var albumSavedController: AlbumSavedController!
    var mockViewController: MockViewController!
    var mockSceneController: MockSceneController!
    var mockDirectoryURL: DocURL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockViewController = MockViewController()
        mockSceneController = MockSceneController(viewController: mockViewController)
        albumSavedController = AlbumSavedController(viewController: mockViewController, sceneController: mockSceneController)
        albumSavedController.cleanAlbum()
        
        XCTAssertNotNil(albumSavedController.albumSavedData.savedMediaURL)
        mockDirectoryURL = DocURL(appDocDirPath: "Saved Media Test")
        try mockDirectoryURL.createItem()
        albumSavedController.albumSavedData.savedMediaURL = mockDirectoryURL
    }

    override func tearDownWithError() throws {
        albumSavedController = nil
        mockViewController = nil
        mockSceneController = nil
        try mockDirectoryURL.removeItem()
        super.tearDown()
    }
    
    func testCommon() {
        XCTAssertTrue(albumSavedController.albumData.albumEmpty)
        XCTAssertEqual(albumSavedController.getAlbumMode(), .saved)
        
        let result = albumSavedController.getTitle()
        XCTAssertEqual(try? (result as? Text).inspect().text().string(), "Saved")
    }

    func testToggleSelectMode() {
        albumSavedController.toggleSelectMode()
        XCTAssertTrue(albumSavedController.albumData.selectMode)
        XCTAssertTrue(albumSavedController.albumSavedData.selectedItems.isEmpty)
        
        albumSavedController.albumData.selectMode = true
        albumSavedController.albumSavedData.selectedItems.append(DocURL(appDocDirPath: "/file/dummyFile"))
        XCTAssertFalse(albumSavedController.albumSavedData.selectedItems.isEmpty)
        albumSavedController.toggleSelectMode()
        XCTAssertFalse(albumSavedController.albumData.selectMode)
        XCTAssertTrue(albumSavedController.albumSavedData.selectedItems.isEmpty)
    }

    func testToggleFilter() {
        albumSavedController.toggleFilter(newFilter: .photos)
        XCTAssertEqual(albumSavedController.albumData.filter, .photos)
        XCTAssertTrue(albumSavedController.albumData.albumEmpty)
        
        let mockFiles = [DocURL(appDocDirPath: "/file/dummyFile1.png"), DocURL(appDocDirPath: "/file/dummyFile2.png")]
        albumSavedController.albumSavedData.albumItems[Date()] = mockFiles
        albumSavedController.toggleFilter(newFilter: .photos)
        XCTAssertFalse(albumSavedController.albumData.albumEmpty)
    }
    
    func testGetSelectStatus() throws {
        albumSavedController.albumSavedData.selectedItems = []
        XCTAssertEqual(try? (albumSavedController.getSelectStatus() as? Text).inspect().text().string(), "Select Items")
        
        let mockFile = albumSavedController.albumSavedData.savedMediaURL!.appendFile(fileName: "testFile.jpg")
        albumSavedController.albumSavedData.selectedItems = [mockFile]
        try Data(count: 999).write(to: mockFile.getURL())
    
        XCTAssertEqual(try? (albumSavedController.getSelectStatus() as? Text).inspect().text().string(), "1 file(s) selected (999.00 B)")
        
        try Data(count: 999999).write(to: mockFile.getURL())
        XCTAssertEqual(try? (albumSavedController.getSelectStatus() as? Text).inspect().text().string(), "1 file(s) selected (999.00 kB)")
        
        try Data(count: 999999999).write(to: mockFile.getURL())
        XCTAssertEqual(try? (albumSavedController.getSelectStatus() as? Text).inspect().text().string(), "1 file(s) selected (999.00 MB)")
        
        try Data(count: 1000000000).write(to: mockFile.getURL())
        XCTAssertEqual(try? (albumSavedController.getSelectStatus() as? Text).inspect().text().string(), "1 file(s) selected (1.00 GB)")
        
        try mockFile.removeItem()
    }
    
    func testGetAlbumContent() throws {
        XCTAssertEqual(try? albumSavedController.getAlbumContent().inspect().findAll(ViewInspector.ViewType.Section.self).count, 0)
        
        let fileURL = self.albumSavedController.albumSavedData.savedMediaURL!.appendFile(fileName: "testFile.jpg")
        let fileURL2 = self.albumSavedController.albumSavedData.savedMediaURL!.appendFile(fileName: "testFile2.jpg")
        let fileURL3 = self.albumSavedController.albumSavedData.savedMediaURL!.appendFile(fileName: "testFile3.mp4")
        try Data(count: 1024).write(to: fileURL.getURL())
        try Data(count: 1024).write(to: fileURL2.getURL())
        try Data(count: 1024).write(to: fileURL3.getURL())
        
        albumSavedController.addToAlbum(file: fileURL)
        albumSavedController.addToAlbum(file: fileURL2)
        albumSavedController.addToAlbum(file: fileURL3)
        XCTAssertFalse(albumSavedController.albumData.albumEmpty)
        
        XCTAssertEqual(try? albumSavedController.getAlbumContent().inspect().findAll(ViewInspector.ViewType.Section.self).count, 1)
        XCTAssertEqual(try? albumSavedController.getAlbumContent().inspect().findAll(ViewInspector.ViewType.Section.self).first?.findAll(ViewInspector.ViewType.AnyView.self).count, 3)
        
        albumSavedController.toggleFilter(newFilter: .photos)
        XCTAssertEqual(try? albumSavedController.getAlbumContent().inspect().findAll(ViewInspector.ViewType.Section.self).count, 1)
        XCTAssertEqual(try? albumSavedController.getAlbumContent().inspect().findAll(ViewInspector.ViewType.Section.self).first?.findAll(ViewInspector.ViewType.AnyView.self).count, 2)
        
        albumSavedController.toggleFilter(newFilter: .videos)
        XCTAssertEqual(try? albumSavedController.getAlbumContent().inspect().findAll(ViewInspector.ViewType.Section.self).count, 1)
        XCTAssertEqual(try? albumSavedController.getAlbumContent().inspect().findAll(ViewInspector.ViewType.Section.self).first?.findAll(ViewInspector.ViewType.AnyView.self).count, 1)
        
        try fileURL.removeItem()
        try fileURL2.removeItem()
        try fileURL3.removeItem()
    }
    
    func testContentInteractionPhoto() throws {
        let fileURL = self.albumSavedController.albumSavedData.savedMediaURL!.appendFile(fileName: "testFile.jpg")
        try Data(count: 1024).write(to: fileURL.getURL())
        albumSavedController.addToAlbum(file: fileURL)
        
        // Test tap for preview
        var imageThumbnail = try albumSavedController.getAlbumContent().inspect().find(ImageThumbnailView.self)
        XCTAssertNotNil(imageThumbnail)
        
        XCTAssertNil(albumSavedController.albumData.albumPreviewController)
        try imageThumbnail.callOnTapGesture()
        XCTAssertNotNil(albumSavedController.albumData.albumPreviewController)
        
        albumSavedController.albumData.albumPreviewController?.trashFile()
        XCTAssertNil(albumSavedController.albumData.albumPreviewController)
        XCTAssertFalse(albumSavedController.isMediaSaved(fileName: "testFile.jpg"))
        
        // Test selection
        try Data(count: 1024).write(to: fileURL.getURL())
        albumSavedController.addToAlbum(file: fileURL)
        albumSavedController.toggleSelectMode()
        imageThumbnail = try albumSavedController.getAlbumContent().inspect().find(ImageThumbnailView.self)
        try imageThumbnail.callOnTapGesture()
        
        XCTAssertEqual(albumSavedController.albumSavedData.selectedItems.count, 1)
        XCTAssertTrue(albumSavedController.albumSavedData.selectedItems.contains(fileURL))
        albumSavedController.toggleSelectMode()
        XCTAssertEqual(albumSavedController.albumSavedData.selectedItems.count, 0)
        
        try fileURL.removeItem()
    }
    
    func testContentDescription() throws {
        let fileURL = self.albumSavedController.albumSavedData.savedMediaURL!.appendFile(fileName: "testFile.jpg")
        let fileURL1 = self.albumSavedController.albumSavedData.savedMediaURL!.appendFile(fileName: "testFile.mp4")
        let fileURL2 = self.albumSavedController.albumSavedData.savedMediaURL!.appendFile(fileName: "testFile.pano")
        try Data(count: 1024).write(to: fileURL.getURL())
        try Data(count: 1024).write(to: fileURL1.getURL())
        try Data(count: 1024).write(to: fileURL2.getURL())
        albumSavedController.addToAlbum(file: fileURL)
        
        var containsSquare = false, containsFill = false, uploadable = false, isPhoto = false, isVideo = false, isPano = false
        for image in (try albumSavedController.getAlbumContent().inspect().findAll(Image.self)) {
            if (try image.actualView().name()) == "square.and.arrow.up.fill" { uploadable = true }
            if (try image.actualView().name()) == "square" { containsSquare = true }
            if (try image.actualView().name()) == "photo.fill" { isPhoto = true }
            if (try image.actualView().name()) == "video.fill" { isVideo = true }
            if (try image.actualView().name()) == "pano.fill" { isPano = true }
        }
        XCTAssertTrue(isPhoto)
        XCTAssertFalse(isVideo)
        XCTAssertFalse(isPano)
        XCTAssertFalse(containsSquare)
        XCTAssertFalse(uploadable)
        
        albumSavedController.addToAlbum(file: fileURL1)
        mockSceneController.sceneData.openedProject.readyToUpload = true
        albumSavedController.toggleSelectMode()
        
        for image in (try albumSavedController.getAlbumContent().inspect().findAll(Image.self)) {
            if (try image.actualView().name()) == "square.and.arrow.up.fill" { uploadable = true }
            if (try image.actualView().name()) == "square" { containsSquare = true }
            if (try image.actualView().name()) == "video.fill" { isVideo = true }
            if (try image.actualView().name()) == "pano.fill" { isPano = true }
        }
        XCTAssertTrue(isPhoto)
        XCTAssertTrue(isVideo)
        XCTAssertTrue(containsSquare)
        XCTAssertTrue(uploadable)
        XCTAssertFalse(isPano)
        
        albumSavedController.addToAlbum(file: fileURL2)
        try albumSavedController.getAlbumContent().inspect().find(ImageThumbnailView.self).callOnTapGesture()
        
        XCTAssertTrue(albumSavedController.albumSavedData.selectedItems.contains(fileURL))
        for image in (try albumSavedController.getAlbumContent().inspect().findAll(Image.self)) {
            if (try image.actualView().name()) == "checkmark.square.fill" { containsFill = true }
            if (try image.actualView().name()) == "pano.fill" { isPano = true }
        }
        
        XCTAssertTrue(isPano)
        XCTAssertTrue(containsFill)
        
        containsSquare = false
        try albumSavedController.getAlbumContent().inspect().find(ImageThumbnailView.self).callOnTapGesture()
        try albumSavedController.getAlbumContent().inspect().find(VideoThumbnailView.self).callOnTapGesture()
        
        XCTAssertFalse(albumSavedController.albumSavedData.selectedItems.contains(fileURL))
        XCTAssertTrue(albumSavedController.albumSavedData.selectedItems.contains(fileURL1))
        for image in (try albumSavedController.getAlbumContent().inspect().findAll(Image.self)) {
            if (try image.actualView().name()) == "square" { containsSquare = true }
        }
        
        XCTAssertTrue(containsSquare)
        
        try fileURL.removeItem()
        try fileURL1.removeItem()
        try fileURL2.removeItem()
    }

    func testSelectAll() {
        let mockFiles = [DocURL(appDocDirPath: "/file/dummyFile1"), DocURL(appDocDirPath: "/file/dummyFile2")]
        albumSavedController.albumSavedData.albumItems[Date()] = mockFiles
        
        albumSavedController.selectAll()
        XCTAssertEqual(albumSavedController.albumSavedData.selectedItems, mockFiles)
        XCTAssertEqual(albumSavedController.getSelectCount(), 2)
        
        albumSavedController.uploadSelected()
        XCTAssertEqual(albumSavedController.getSelectCount(), 0)
        XCTAssertEqual(albumSavedController.albumSavedData.selectedItems, [])
        XCTAssertTrue(mockSceneController.lastUploadRequest.contains(mockFiles[0]))
        XCTAssertTrue(mockSceneController.lastUploadRequest.contains(mockFiles[1]))
    }

    func testUnselectAll() {
        albumSavedController.albumSavedData.selectedItems = [DocURL(appDocDirPath: "/file/dummyFile")]
        albumSavedController.unselectAll()
        XCTAssertTrue(albumSavedController.albumSavedData.selectedItems.isEmpty)
    }

    func testAddToAlbum() throws {
        XCTAssertNotNil(self.albumSavedController.albumSavedData.savedMediaURL)
        let fileURL = self.albumSavedController.albumSavedData.savedMediaURL!.appendFile(fileName: "testFile.jpg")
        let fileURL2 = self.albumSavedController.albumSavedData.savedMediaURL!.appendFile(fileName: "testFile2.jpg")
        try Data(count: 1024).write(to: fileURL.getURL())
        try Data(count: 1024).write(to: fileURL2.getURL())
        
        albumSavedController.addToAlbum(file: DocURL(dirURL: URL(fileURLWithPath: "/file"), fileName: "notSavedFile.png"))
        XCTAssertEqual(mockViewController.lastAlertTitle,"Error Adding Media To Saved Album")
        
        albumSavedController.addToAlbum(file: fileURL)
        albumSavedController.addToAlbum(file: fileURL2)
            
        XCTAssertTrue(albumSavedController.albumSavedData.albumItems.flatMap({ $0.value }).contains(fileURL))
        XCTAssertTrue(albumSavedController.isMediaSaved(fileName: "testFile.jpg"))
        XCTAssertTrue(albumSavedController.isMediaSaved(fileName: "testFile2.jpg"))
        
        albumSavedController.addToAlbum(file: fileURL)
        albumSavedController.addToAlbum(file: fileURL)
        
        XCTAssertTrue(albumSavedController.albumSavedData.albumItems.flatMap({ $0.value }).count == 2)
            
        try fileURL.removeItem()
    }
    
    func testSaveImageFromPicker() {
        do {
            try albumSavedController.saveImageFromPicker(data: Data(count: 1024))
        } catch { XCTFail("Unable to save img from picker") }
        
        XCTAssertEqual(albumSavedController.albumSavedData.albumItems.count, 1)
        XCTAssertEqual(albumSavedController.albumSavedData.albumItems.first!.value.count, 1)
        albumSavedController.selectAll()
        albumSavedController.trashSelected()
        XCTAssertEqual(albumSavedController.albumSavedData.albumItems.count, 0)
    }
    
    func testLoadSavedMediaAndTrash() throws {
        albumSavedController.albumSavedData.savedMediaURL = nil
        albumSavedController.loadSavedMedia()
        XCTAssertNotNil(mockViewController.lastAlertMessage)
        XCTAssertTrue(mockViewController.lastAlertMessage!.contains("Error loading files from Saved Media directory: The operation couldn’t be completed. (NSURLErrorDomain error -1000.)"))
        
        albumSavedController.albumSavedData.savedMediaURL = mockDirectoryURL
        try mockDirectoryURL.removeItem()
        
        albumSavedController.loadSavedMedia()
        
        XCTAssertNotNil(mockViewController.lastAlertMessage)
        XCTAssertTrue(mockViewController.lastAlertMessage!.contains("Error loading files from Saved Media directory: The file “Saved Media Test” couldn’t be opened because there is no such file."))
        
        try mockDirectoryURL.createItem()
            
        let mockFileURL = mockDirectoryURL.appendFile(fileName: "testFile.jpg")
        let mockFileURL1 = mockDirectoryURL.appendFile(fileName: "_tmp.testFile.jpg")
        let mockFileURL2 = mockDirectoryURL.appendFile(fileName: "_tmp.testFile2.jpg")
        let mockFileURL3 = DocURL(appDocDirPath: "/file/dummyFile1")
        try Data(count: 1024).write(to: mockFileURL.getURL())
        try Data(count: 1024).write(to: mockFileURL1.getURL())
        try Data(count: 1024).write(to: mockFileURL2.getURL())
        
        albumSavedController.toggleFilter(newFilter: .photos)
        
        albumSavedController.loadSavedMedia()
        
        XCTAssertTrue(albumSavedController.albumSavedData.albumItems.flatMap({ $0.value }).contains(mockFileURL))
        XCTAssertFalse(albumSavedController.albumSavedData.albumItems.flatMap({ $0.value }).contains(mockFileURL1))
        XCTAssertFalse(albumSavedController.albumSavedData.albumItems.flatMap({ $0.value }).contains(mockFileURL2))
        XCTAssertFalse(albumSavedController.albumData.albumEmpty)
            
        albumSavedController.trashFiles(files: [mockFileURL, mockFileURL1])
        XCTAssertFalse(mockFileURL.existsItem())
        XCTAssertTrue(mockFileURL1.existsItem())
        XCTAssertNotNil(mockViewController.lastAlertMessage)
        XCTAssertTrue(mockViewController.lastAlertMessage!.contains("Trash request for file that is not in album!"))
        
        albumSavedController.trashFiles(files: [mockFileURL3])
        XCTAssertNotNil(mockViewController.lastAlertMessage)
        XCTAssertTrue(mockViewController.lastAlertMessage!.contains("Saved media couldn\\\'t be removed!"))
        
        XCTAssertTrue(albumSavedController.albumData.albumEmpty)
        try mockFileURL.removeItem()
        try mockFileURL2.removeItem()
        try mockFileURL.removeItem()
    }
    
    func testTrashSelected() {
        XCTAssertNotNil(self.albumSavedController.albumSavedData.savedMediaURL)
        let fileURL = self.albumSavedController.albumSavedData.savedMediaURL!.appendFile(fileName: "testFile.jpg")
        try? Data(count: 1024).write(to: fileURL.getURL())
        
        albumSavedController.addToAlbum(file: fileURL)
        albumSavedController.albumSavedData.selectedItems.append(fileURL)
        
        XCTAssertFalse(albumSavedController.albumData.albumEmpty)
        albumSavedController.trashSelected()
        XCTAssertTrue(albumSavedController.albumData.albumEmpty)
    }
    
    func testIsPhoto() {
        let photoURL = DocURL(appDocDirPath: "/file/dummyFile", fileName: "test.jpg")
        XCTAssertTrue(albumSavedController.isPhoto(file: photoURL))
            
        let nonPhotoURL = DocURL(appDocDirPath: "/file/dummyFile", fileName: "test.txt")
        XCTAssertFalse(albumSavedController.isPhoto(file: nonPhotoURL))
    }

    func testIsVideo() {
        let videoURL = DocURL(appDocDirPath: "/file/dummyFile", fileName: "test.mp4")
        XCTAssertTrue(albumSavedController.isVideo(file: videoURL))
            
        let nonVideoURL = DocURL(appDocDirPath: "/file/dummyFile", fileName: "test.jpg")
        XCTAssertFalse(albumSavedController.isVideo(file: nonVideoURL))
    }

    func testIsPano() {
        let panoURL = DocURL(appDocDirPath: "/file/dummyFile", fileName: "test.pano")
        XCTAssertTrue(albumSavedController.isPano(file: panoURL))
            
        let nonPanoURL = DocURL(appDocDirPath: "/file/dummyFile", fileName: "test.jpg")
        XCTAssertFalse(albumSavedController.isPano(file: nonPanoURL))
    }
}
