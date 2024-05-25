import SwiftUI

/**
 `GetProjectClearTasks` is a command derived from `ProjectCommand` that is specifically designed to clear the statuses of multiple tasks associated with a project on a RealityCapture node (RCNode). It sends a GET request to the RCNode's API endpoint to clear the current states of specified tasks.
 
 The command plays a crucial role in applications that require efficient management and resetting of task executions within projects, especially in environments where task statuses need to be cleared to prevent clutter or conflicts in workflow.
 */
public class GetProjectClearTasks: ProjectCommand {
    /// Reference to the `ViewController` responsible for managing navigation, presentation of different views within the application and displaying errors.
    private let viewController = CRFly.shared.viewController
    
    /// Initializes a new instance of the `GetProjectClearTasks` command with a specified array of task IDs.
    public init(tasks: [String] = []) {
        let urlEncodedArray = tasks.map { element in
            return element.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        }
        let joinedString = urlEncodedArray.count > 0 ? "?taskIds=\(urlEncodedArray.joined(separator: ","))" : ""
        
        let structure = Structure(path: "/project/cleartasks\(joinedString)", method: .get, dataOutputType: .none, acceptStatusCode: 200, errorTitle: "Error Clearing RCNode Project Tasks Statuses")
        super.init(structure: structure, requestedProjectState: .opened, executionDisableInteraction: false)
    }
    
    /// Processes the HTTP response upon successful communication with the RCNode, updating task statuses accordingly.
    override internal func validResponseAction(parsedResponse: HTTPResponseParser, completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        completion(true, false, nil)
    }
}
