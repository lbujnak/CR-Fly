import SwiftUI

/// `CommandQueueController` manages a queue of commands to be executed sequentially. It ensures safe execution of operations, handling retries and error conditions.
public class CommandQueueController: NSObject {
    /// Reference to the `ViewController` responsible for managing navigation, presentation of different views within the application and displaying errors.
    private let viewController: ViewController
    
    /// The queue of commands to be executed.
    private var commandQueue: [Command] = []
    
    /// A boolean flag that Indicates whether a command is currently being executed.
    private var isExecutingCommand = false
    
    /// An integer that represents maximum number of retries allowed for a failed command.
    private let commandRetries: Int
    
    /// An integer, that represents timeout for execution (in milliseconds) before retrying a failed command.
    private let commandRetryTimeout: Int
    
    /// An integer representing attempted retries for the current command.
    private var currentCommandRetryCount: Int = 0
    
    /// A boolean flag indicating whether command execution is enabled.
    var commandExecutionEnabled = false {
        didSet {
            if !self.commandQueue.isEmpty, !self.isExecutingCommand {
                self.processNextCommand()
            }
        }
    }
    
    /// Initializes a new instance of `CommandQueueController`.
    public init(commandRetries: Int, commandRetryTimeout: Int, viewController: ViewController) {
        self.commandRetries = commandRetries
        self.commandRetryTimeout = commandRetryTimeout
        self.viewController = viewController
    }
    
    /// Adds a command to the queue and starts processing if execution is enabled.
    public func pushCommand(command: Command) {
        self.commandQueue.append(command)
        if !self.isExecutingCommand {
            self.isExecutingCommand = true
            DispatchQueue.main.async {
                self.processNextCommand()
            }
        }
    }
    
    /// Adds a command to the command queue only if a command of the same type is not already present in the queue.
    public func pushCommandOnce(command: Command) {
        if !self.commandQueue.contains(where: { type(of: $0) == type(of: command) }) {
            self.pushCommand(command: command)
        }
    }
    
    /// Adds a command to the front of the command queue. This command will be the next one executed when `processNextCommand()` is called.
    public func prependCommand(command: Command) {
        self.commandQueue.insert(command, at: 0)
    }
    
    /// Returns the count of commands in the queue.
    public func getCommandInQueueCount() -> Int {
        self.commandQueue.count
    }
    
    /// Removes all commands from the queue.
    public func clearCommandQueue() {
        self.commandQueue.removeAll()
    }
    
    /// Processes the next command in the queue, handling retries and errors.
    public func processNextCommand() {
        if self.commandQueue.isEmpty || !self.commandExecutionEnabled {
            self.isExecutingCommand = false
            return
        }
        
        let command = self.commandQueue.removeFirst()
        command.execute { success, retryable, error in
            if !self.commandExecutionEnabled {
                self.prependCommand(command: command)
                self.isExecutingCommand = false
                return
            }
            
            if success {
                self.currentCommandRetryCount = 0
            } else {
                self.currentCommandRetryCount += 1
                if self.currentCommandRetryCount > self.commandRetries || !retryable {
                    DispatchQueue.main.async {
                        if error != nil {
                            self.viewController.showSimpleAlert(title: error!.0, msg: Text("\(error!.1)"))
                        } else {
                            self.viewController.showSimpleAlert(title: "Unexpected Error Occurred", msg: Text("An error occurred during execution due to an undefined error message!"))
                        }
                    }
                    self.currentCommandRetryCount = 0
                } else {
                    self.prependCommand(command: command)
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(self.commandRetryTimeout)) {
                        self.processNextCommand()
                    }
                    return
                }
            }
            DispatchQueue.main.async {
                self.processNextCommand()
            }
        }
    }
}
