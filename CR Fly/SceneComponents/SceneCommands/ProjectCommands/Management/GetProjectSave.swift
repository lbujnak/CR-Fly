import Foundation

/**
 `GetProjectSave` is a command class derived from `ProjectCommand` designed to handle the saving of an open project on a RealityCapture node (RCNode). It sends a GET request to the RCNode's API to save the currently open project with a specified name.
 
 The command makes sure that the project data is safely stored before any further operations that might rely on these changes being committed, thus maintaining operational integrity and data coherence within the application.
 */
public class GetProjectSave: ProjectCommand {
    
    /// The name of the project to be saved.
    private let projectName: String
    
    /// Initializes a new instance of the `GetProjectSave` command with the specified project name.
    public init(projectName: String) {
        self.projectName = projectName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let structure = Structure(path: "/project/save?name=\(self.projectName)", method: .get, dataOutputType: .none, acceptStatusCode: 202, errorTitle: "Error Saving RCNode Project")
        super.init(structure: structure, requestedProjectState: .opened, executionDisableInteraction: true)
    }
    
    /// Overrides the base execute command method to delete project and handle the response to ensure the project context is appropriately set.
    override public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        if self.projectName == "" {
            completion(false, false, ("Error Saving RCNode Project", "Project name could not be encoded."))
        } else {
            super.execute(completion: completion)
        }
    }
    
    /// Handles a valid response from the RCNode server after successfully saving a project.
    override internal func validResponseAction(parsedResponse _: HTTPResponseParser, completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        DispatchQueue.main.async {
            self.sceneController.sceneData.openedProject.savedChangeCounter = self.sceneController.sceneData.openedProject.changeCounter
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            self.sceneController.pushCommand(command: GetNodeProjects())
        }
        completion(true, false, nil)
    }
}
