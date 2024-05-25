import Foundation

/**
 `Command` protocol defines a contract for objects capable of executing commands.
 
The `Command` protocol encapsulates the behavior of commands that can be executed within the application. It defines a single method `execute(completion:)` that must be implemented by conforming types to perform the command's intended action and provide feedback through the completion handler.
 */
public protocol Command {
    /// Executes the command and calls the completion handler with the result.
    func execute(completion: @escaping (_ success: Bool, _ retryable: Bool, _ error: (String, String)?) -> Void)
}
