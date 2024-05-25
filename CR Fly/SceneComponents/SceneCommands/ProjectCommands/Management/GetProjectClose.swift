import Foundation

/**
 `GetProjectClose` is a specialized command derived from `ProjectCommand` that is responsible for closing the currently open project on a RealityCapture node (RCNode). It sends a GET request to the RCNode's API to close the project, ensuring that all resources are properly released and the project state is reset.
 
 The execution of this command is critical for maintaining system stability and preventing data leaks by ensuring that all project-specific resources are freed up on the RCNode.
 */
public class GetProjectClose: ProjectCommand {
    /// Initializes a new instance of the `GetProjectClose` command.
    public init() {
        let structure = Structure(path: "/project/close", method: .get, dataOutputType: .none, acceptStatusCode: 200, errorTitle: "Error Closing RCNode Project")
        super.init(structure: structure, requestedProjectState: .opened, executionDisableInteraction: true)
    }
    
    /// Handles a valid response from the RCNode server after successfully creating a project.
    override internal func validResponseAction(parsedResponse _: HTTPResponseParser, completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        DispatchQueue.main.async {
            self.sceneController.projectUnload()
        }
        completion(true, false, nil)
    }
}
