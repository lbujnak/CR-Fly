import XCTest
import SwiftUI
@testable import CR_Fly

final class CommandQueueControllerTest: XCTestCase {
    var commandQueueController: CommandQueueController!
    var mockViewController: MockViewController!

    override func setUp() {
        super.setUp()
        mockViewController = MockViewController()
        commandQueueController = CommandQueueController(commandRetries: 1, commandRetryTimeout: 1000, viewController: mockViewController)
        commandQueueController.commandExecutionEnabled = true
    }

    override func tearDown() {
        commandQueueController = nil
        mockViewController = nil
        super.tearDown()
    }
    
    func testCommandPushOnce() {
        let sleep = XCTestExpectation(description: "Sleep")
        let expectation = XCTestExpectation(description: "Command should be executed")
        let expectation2 = XCTestExpectation(description: "Command should be executed")
        
        commandQueueController.commandExecutionEnabled = false
        let command = MockCommand(success: true, retryable: false, completion: { expectation.fulfill() })
        let command2 = MockCommand2(success: true, retryable: false, completion: { expectation2.fulfill() })
        commandQueueController.pushCommand(command: command)
        commandQueueController.pushCommandOnce(command: command)
        
        XCTAssertEqual(commandQueueController.getCommandInQueueCount(), 1)
        commandQueueController.pushCommandOnce(command: command2)
        
        DispatchQueue.main.async { sleep.fulfill() }
        wait(for: [sleep], timeout: 2.0)
        XCTAssertEqual(commandQueueController.getCommandInQueueCount(), 2)
        commandQueueController.commandExecutionEnabled = true
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(command.executeCalled)
        XCTAssertEqual(command.executionCount, 1)
        
        wait(for: [expectation2], timeout: 1.0)
        
        XCTAssertTrue(command2.executeCalled)
        XCTAssertEqual(command2.executionCount, 1)
    }
    
    func testCommandPrepend() {
        let expectation1 = XCTestExpectation(description: "Command1 should be executed")
        let expectation2 = XCTestExpectation(description: "Command2 should be executed")
        
        commandQueueController.commandExecutionEnabled = false
        let command1 = MockCommand(success: true, retryable: false, completion: { expectation1.fulfill() })
        let command2 = MockCommand(success: true, retryable: false, completion: { expectation2.fulfill() })
        
        commandQueueController.pushCommand(command: command1)
        commandQueueController.prependCommand(command: command2)
        
        XCTAssertEqual(commandQueueController.getCommandInQueueCount(), 2)
        commandQueueController.commandExecutionEnabled = true
        
        wait(for: [expectation2], timeout: 1.0)
        XCTAssertTrue(command2.executeCalled)
        XCTAssertFalse(command1.executeCalled)
    }

    func testPushCommandExecutesCommand() {
        commandQueueController.commandExecutionEnabled = false
        let expectation = XCTestExpectation(description: "Command should be executed")
        let command = MockCommand(success: true, retryable: false, completion: { expectation.fulfill() })
        
        commandQueueController.pushCommand(command: command)
        XCTAssertFalse(command.executeCalled)
        commandQueueController.commandExecutionEnabled = true
        
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(command.executeCalled)
        XCTAssertEqual(command.executionCount, 1)
        XCTAssertEqual(commandQueueController.getCommandInQueueCount(), 0)
    }
    
    func testCommandExecution_Canceled() {
        let sleep = XCTestExpectation(description: "Sleep")
        let sleep2 = XCTestExpectation(description: "Sleep")
        let expectation = XCTestExpectation(description: "Command should be executed")
        let command = MockCommand2(success: true, retryable: false, completion: { expectation.fulfill() })
        commandQueueController.pushCommand(command: command)
        
        DispatchQueue.main.async { sleep.fulfill() }
        wait(for: [sleep], timeout: 2.0)
        
        XCTAssertEqual(commandQueueController.getCommandInQueueCount(), 0)
        commandQueueController.commandExecutionEnabled = false
        
        DispatchQueue.main.async { sleep2.fulfill() }
        wait(for: [sleep2], timeout: 2.0)
        
        XCTAssertTrue(command.executeCalled)
        XCTAssertEqual(commandQueueController.getCommandInQueueCount(), 1)
    }
    
    func testCommandExecution_Failure() {
        let expectation = XCTestExpectation(description: "Command should be executed")
        let command = MockCommand(success: false, retryable: true, error: ("Error", "Failed execution"), completion: { expectation.fulfill() })
        
        commandQueueController.pushCommand(command: command)
        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(commandQueueController.getCommandInQueueCount(), 1)
        XCTAssertEqual(mockViewController.lastAlertTitle, nil)
        
        let sleep = XCTestExpectation(description: "Command retries timeout problem")
        let sleep1 = XCTestExpectation(description: "Command retries after did not execute")
            
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) { sleep.fulfill() }
        wait(for: [sleep], timeout: 0.7)
        
        XCTAssertEqual(command.executionCount, 1)
        XCTAssertNil(mockViewController.lastAlertTitle)
        XCTAssertEqual(commandQueueController.getCommandInQueueCount(), 1)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1200)) { sleep1.fulfill() }
        wait(for: [sleep1], timeout: 1.5)
        
        XCTAssertEqual(command.executionCount, 2)
        XCTAssertNotNil(mockViewController.lastAlertTitle)
        XCTAssertEqual(commandQueueController.getCommandInQueueCount(), 0)
        XCTAssertNotEqual(mockViewController.lastAlertTitle, nil)
    }

    func testCommandExecution_Failure_NonRetryable() {
        let expectation = XCTestExpectation(description: "Command should be executed")
        let expectation1 = XCTestExpectation(description: "Command should be executed")
        let command = MockCommand(success: false, retryable: false, error: ("Error", "Critical failure"), completion: { expectation.fulfill() })
        let command1 = MockCommand(success: false, retryable: false, error: nil, completion: { expectation1.fulfill() })
        commandQueueController.pushCommand(command: command)
        commandQueueController.pushCommand(command: command1)
        XCTAssertEqual(commandQueueController.getCommandInQueueCount(), 2)
        
        wait(for: [expectation], timeout: 5.0)
        
        let sleep = XCTestExpectation(description: "Sleep")
        DispatchQueue.main.async { sleep.fulfill() }
        wait(for: [sleep], timeout: 5.0)
        XCTAssertEqual(commandQueueController.getCommandInQueueCount(), 0)
        XCTAssertEqual(mockViewController.lastAlertTitle, "Error")
        XCTAssertTrue(mockViewController.lastAlertMessage?.contains("Critical failure") ?? false)
        
        wait(for: [expectation1], timeout: 5.0)
        
        let sleep2 = XCTestExpectation(description: "Sleep")
        DispatchQueue.main.async { sleep2.fulfill() }
        wait(for: [sleep2], timeout: 5.0)

        XCTAssertEqual(commandQueueController.getCommandInQueueCount(), 0)
        XCTAssertEqual(mockViewController.lastAlertTitle, "Unexpected Error Occurred")
        XCTAssertTrue(mockViewController.lastAlertMessage?.contains("An error occurred during execution due to an undefined error message!") ?? false)
    }
    
    func testCommandMultipleExecution() {
        commandQueueController.commandExecutionEnabled = false
        var eCommand1 = false, eCommand2 = false, eCommand3 = false
        let expectation = XCTestExpectation(description: "Commands should be executed")
        let command1 = MockCommand(success: true, retryable: false, completion: { eCommand1 = true })
        let command2 = MockCommand(success: true, retryable: false, completion: { eCommand2 = true })
        let command3 = MockCommand(success: true, retryable: false, completion: { eCommand3 = true; expectation.fulfill() })
        commandQueueController.pushCommand(command: command1)
        commandQueueController.pushCommand(command: command2)
        commandQueueController.pushCommand(command: command3)
        
        XCTAssertEqual(commandQueueController.getCommandInQueueCount(), 3)
        commandQueueController.commandExecutionEnabled = true
        
        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(commandQueueController.getCommandInQueueCount(), 0)
        XCTAssertEqual(eCommand1, true)
        XCTAssertEqual(eCommand2, true)
        XCTAssertEqual(eCommand3, true)
    }
    
    func testQueueStopped() {
        
    }

    func testClearCommandQueue() {
        commandQueueController.commandExecutionEnabled = false
        let command1 = MockCommand(success: true, retryable: false)
        let command2 = MockCommand(success: false, retryable: true)
        commandQueueController.pushCommand(command: command1)
        commandQueueController.pushCommand(command: command2)

        commandQueueController.clearCommandQueue()
        XCTAssertEqual(commandQueueController.getCommandInQueueCount(), 0)
    }
}
