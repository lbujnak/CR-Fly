import SwiftUI
@testable import CR_Fly

final class MockDroneController: CommandQueueController, DroneController {
    var droneData = DroneData()
    var speedCalcIdentifier = ""
    
    init(viewController: ViewController) {
        super.init(commandRetries: 0, commandRetryTimeout: 0, viewController: viewController)
    }
    
    func enterFromBackground() { }
    func leaveToBackground() { }
    func manageDownload(action: MediaTransferAction) { }
    func uploadCanceledFor(fileNames: Set<String>) { }
    func openFPVView() { }
}
