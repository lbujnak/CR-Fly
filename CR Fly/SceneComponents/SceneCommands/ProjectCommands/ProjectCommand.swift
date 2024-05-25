import Foundation

/**
 `ProjectCommand` is a command class that extends `RCNodeCommand` tailored to manage state transitions for projects within a RealityCapture Node (RCNode). It modifies project states such as opening, closing, or checking project status.
 
 - Usage: This command is utilized to securely manage project states within an RCNode, ensuring that transitions such as opening or closing a project are handled gracefully and atomically.
 */
public class ProjectCommand: RCNodeCommand {
    /**
     `RequestedProjectState` defines potential states that can be requested for a project within the RealityCapture Node environment.
     
     This enumeration is used to specify the desired outcome when executing a `ProjectCommand`. It helps ensure that the command aligns with the current operational needs, whether that involves opening a new project, closing an existing one, or maintaining the status quo.
     */
    public enum RequestedProjectState {
        /// There is not any restriction for project.
        case none
        
        /// The project should be closed.
        case closed
        
        /// The project should be opened.
        case opened
    }
    
    /// An enumeration that specifies the desired state transition for the project (`none`, `closed`, `opened`).
    private let requestedProjectState: RequestedProjectState
    
    /// A boolean flag indicating whether the UI should be disabled during the execution of this command. This is typically used to prevent user interaction during critical operations that should not be interrupted.
    private let executionDisableInteraction: Bool
    
    /**
     Initializes a `ProjectCommand` with specified configurations for handling projects in a RealityCapture Node.
     
     - Parameter `structure`: The structure defining the HTTP request parameters such as path, method, and expected data output type.
     - Parameter `requestedProjectState`: The desired state of the project (`none`, `closed`, `opened`) to align the command execution with the intended project lifecycle events.
     - Parameter `executionDisableInteraction`: If set to `true`, the user interface interactions are disabled during the execution of this command. This is typically used to prevent user interference during critical operations such as opening or closing projects, ensuring a smooth and error-free process.
     
     This initializer sets up the `ProjectCommand` with necessary details to effectively manage project state transitions while optionally locking the UI to safeguard against unintended user actions during command execution.
     */
    public init(structure: Structure, requestedProjectState: RequestedProjectState, executionDisableInteraction: Bool) {
        self.requestedProjectState = requestedProjectState
        self.executionDisableInteraction = executionDisableInteraction
        super.init(structure: structure)
    }
    
    /// Overrides the execute method from RCNodeCommand. It first checks if the current project state matches the requested state. If not, it proceeds with the execution of the command. The command may temporarily disable user interaction based on executionDisableInteraction to prevent changes during critical operations. Upon completion, it either re-enables interaction or provides the result of the command execution.
    override public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        if (self.requestedProjectState == .opened && !sceneController.sceneData.openedProject.loaded) ||
            (self.requestedProjectState == .closed && sceneController.sceneData.openedProject.loaded) {
            completion(true, false, nil)
        } else {
            if self.executionDisableInteraction {
                DispatchQueue.main.async { self.sceneController.sceneData.disableUIInteraction = true }
            }
            super.execute(completion: { v1, v2, v3 in
                if self.executionDisableInteraction {
                    DispatchQueue.main.async { self.sceneController.sceneData.disableUIInteraction = false }
                }
                completion(v1, v2, v3)
            })
        }
    }
}
