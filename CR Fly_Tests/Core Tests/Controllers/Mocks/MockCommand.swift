import Foundation
@testable import CR_Fly

final class MockCommand: Command {
    var executeCalled = false
    var executeShouldSucceed: Bool
    var retryable: Bool
    var executionCount: Int = 0
    var error: (String, String)?
    var completion: () -> Void

    init(success: Bool, retryable: Bool, error: (String, String)? = nil, completion: @escaping () -> Void = { }) {
        self.executeShouldSucceed = success
        self.retryable = retryable
        self.error = error
        self.completion = completion
    }

    func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        completion(executeShouldSucceed, retryable, error)
        executeCalled = true
        self.executionCount += 1
        self.completion()
    }
}
