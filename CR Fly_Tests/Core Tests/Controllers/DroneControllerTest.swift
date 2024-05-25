import XCTest
@testable import CR_Fly

final class DroneControllerTest: XCTestCase {

    var droneController: MockDroneController!
    var viewController: MockViewController!
    
    override func setUp() {
        super.setUp()
        viewController = MockViewController()
        droneController = MockDroneController(viewController: viewController)
    }

    override func tearDown() {
        droneController = nil
        viewController = nil
        super.tearDown()
    }
    
    func testUploadSpeedCalc() {
        droneController.droneData.mediaDownloadState = MediaDownloadState(transferPaused: false, transferForcePaused: false,  speedCalcLastBytes: 0 , transferedBytes: 5000)
        droneController.startUpdatingDownloadSpeed()
        
        let expectation = XCTestExpectation(description: "Sleep")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { expectation.fulfill() }
        wait(for: [expectation], timeout: 2)
        
        XCTAssertEqual(droneController.droneData.mediaDownloadState?.speedCalcLastBytes ?? 0, 5000)
        XCTAssertEqual(droneController.droneData.mediaDownloadState?.transferSpeed ?? 0, 10000)
        droneController.droneData.mediaDownloadState?.transferedBytes = 10000
        droneController.startUpdatingDownloadSpeed()
        
        let expectation1 = XCTestExpectation(description: "Sleep")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { expectation1.fulfill() }
        wait(for: [expectation1], timeout: 2)
            
        XCTAssertEqual(droneController.droneData.mediaDownloadState?.speedCalcLastBytes ?? 0, 10000)
        XCTAssertEqual(droneController.droneData.mediaDownloadState?.transferSpeed ?? 0, 10000)
        
        let expectation2 = XCTestExpectation(description: "Sleep")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) { expectation2.fulfill() }
        wait(for: [expectation2], timeout: 2)
            
        droneController.droneData.mediaDownloadState?.transferPaused = true
        XCTAssertEqual(droneController.droneData.mediaDownloadState?.speedCalcLastBytes ?? 0, 10000)
        XCTAssertEqual(droneController.droneData.mediaDownloadState?.transferSpeed ?? 0, 0)
    }
}
