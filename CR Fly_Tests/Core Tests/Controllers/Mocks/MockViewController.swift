import SwiftUI
@testable import CR_Fly

final class MockViewController: ViewController {
    var lastAlertTitle: String?
    var lastAlertMessage: String?

    override func showSimpleAlert(title: String, msg: Text) {
        lastAlertTitle = title
        lastAlertMessage = String(describing: msg)
    }
}
