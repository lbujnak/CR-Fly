import Foundation
@testable import CR_Fly

final class MockObserver: HTTPConnectionStateObserver {
    var onStateChange: ((HTTPConnection.HTTPConnectionState) -> Void)?
    var lastObservedState: HTTPConnection.HTTPConnectionState = .started

    func observeConnection(newState: HTTPConnection.HTTPConnectionState) {
        if onStateChange != nil {
            onStateChange!(newState)
        }
        self.lastObservedState = newState
    }

    func getUniqueId() -> String {
        return UUID().uuidString
    }
}
