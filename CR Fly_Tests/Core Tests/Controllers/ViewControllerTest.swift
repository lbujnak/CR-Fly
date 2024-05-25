import XCTest
import SwiftUI
@testable import CR_Fly

final class ViewControllerTest: XCTestCase {
    
    var viewController: ViewController!
    
    override func setUp() {
        super.setUp()
        viewController = ViewController()
        viewController.addView(type: .mainView, view: MockTextView(txt: "Main View"))
        viewController.addView(type: .albumView, view: MockTextView(txt: "Album View"))
    }
    
    override func tearDown() {
        viewController = nil
        super.tearDown()
    }
    
    func testAddView() {
        let newView = MockTextView(txt: "New View")
        
        viewController.addView(type: .empty, view: newView)
        viewController.displayView(type: .empty, addPreviousToHistory: false)
        
        XCTAssertTrue(viewController.getViewType() == .empty)
    }
    
    func testDisplayView() {
        viewController.displayView(type: .mainView, addPreviousToHistory: false)
        XCTAssertEqual(viewController.currentView.0, .mainView)
        
        viewController.displayView(type: .droneFPVView, addPreviousToHistory: false)
        XCTAssertFalse(viewController.alertErrors.isEmpty)
    }
    
    func testDisplayPreviousView() {
        viewController.displayView(type: .mainView, addPreviousToHistory: false)
        viewController.displayView(type: .albumView, addPreviousToHistory: true)
        XCTAssertTrue(viewController.alertErrors.isEmpty)
        XCTAssertEqual(viewController.currentView.0, .albumView)
        
        viewController.displayPreviousView()
        XCTAssertTrue(viewController.alertErrors.isEmpty)
        XCTAssertEqual(viewController.currentView.0, .mainView)
        
        viewController.displayPreviousView()
        XCTAssertFalse(viewController.alertErrors.isEmpty)
        XCTAssertEqual(viewController.currentView.0, .mainView)
        
        viewController.clearAlertError()
        viewController.displayView(view: MockTextView(txt: "Test"), type: .custom, addPreviousToHistory: true)
        XCTAssertEqual(viewController.currentView.0, .custom)
        viewController.displayPreviousView()
        XCTAssertEqual(viewController.currentView.0, .mainView)
    }
    
    func testShowSimpleAlert() {
        viewController.showSimpleAlert(title: "Test Alert", msg: Text("This is a test."))
        
        XCTAssertTrue(viewController.showAlertError)
        XCTAssertEqual(viewController.alertErrors.count, 1)
        XCTAssertEqual(viewController.alertErrors[0].0, "Test Alert")
        viewController.clearAlertError()
        XCTAssertEqual(viewController.alertErrors.count, 0)
    }
}
