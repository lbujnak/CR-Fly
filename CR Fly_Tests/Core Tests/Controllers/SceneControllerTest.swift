import XCTest
@testable import CR_Fly

final class SceneControllerTest: XCTestCase {

    var sceneController: MockSceneController!
    var viewController: MockViewController!
    
    override func setUp() {
        super.setUp()
        viewController = MockViewController()
        sceneController = MockSceneController(viewController: viewController)
    }

    override func tearDown() {
        sceneController = nil
        viewController = nil
        super.tearDown()
    }
    
    func testUploadSpeedCalc() {
        sceneController.sceneData.mediaUploadState = MediaUploadState(transferPaused: false, transferForcePaused: false,  speedCalcLastBytes: 0 , transferedBytes: 5000)
        sceneController.startUpdatingUploadSpeed()
        
        let expectation = XCTestExpectation(description: "Sleep")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { expectation.fulfill() }
        wait(for: [expectation], timeout: 2)
        
        XCTAssertEqual(sceneController.sceneData.mediaUploadState?.speedCalcLastBytes ?? 0, 5000)
        XCTAssertEqual(sceneController.sceneData.mediaUploadState?.transferSpeed ?? 0, 10000)
        sceneController.sceneData.mediaUploadState?.transferedBytes = 10000
        sceneController.startUpdatingUploadSpeed()
        
        let expectation1 = XCTestExpectation(description: "Sleep")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { expectation1.fulfill() }
        wait(for: [expectation1], timeout: 2)
            
        XCTAssertEqual(sceneController.sceneData.mediaUploadState?.speedCalcLastBytes ?? 0, 10000)
        XCTAssertEqual(sceneController.sceneData.mediaUploadState?.transferSpeed ?? 0, 10000)
        
        let expectation2 = XCTestExpectation(description: "Sleep")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) { expectation2.fulfill() }
        wait(for: [expectation2], timeout: 2)
            
        sceneController.sceneData.mediaUploadState?.transferPaused = true
        XCTAssertEqual(sceneController.sceneData.mediaUploadState?.speedCalcLastBytes ?? 0, 10000)
        XCTAssertEqual(sceneController.sceneData.mediaUploadState?.transferSpeed ?? 0, 0)
    }
}
