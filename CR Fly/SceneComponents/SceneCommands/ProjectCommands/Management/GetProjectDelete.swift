import Foundation

/**
 `GetProjectDelete` is a command class derived from `ProjectCommand` designed to handle the deletion of an existing project on a RealityCapture node (RCNode). It sends a GET request to the RCNode's API to delete a project identified by a specific GUID.
 
 The command ensures that the project is properly deleted from the RCNode, maintaining data coherence and freeing up resources within the application.
 */
public class GetProjectDelete: ProjectCommand {
    /// The GUID of the project to be deleted.
    private let projectID: String
    
    /// Initializes a new instance of the `GetProjectDelete` command with a specified project name and project ID (GUID).
    public init(projectID: String) {
        self.projectID = projectID
        
        let structure = Structure(path: "/project/delete?guid=\(projectID)", method: .get, dataOutputType: .none, acceptStatusCode: 200, errorTitle: "Error Deleting RCNode Project")
        super.init(structure: structure, requestedProjectState: .none, executionDisableInteraction: true)
    }
    
    /// Overrides the base execute command method to delete project and handle the response to ensure the project context is appropriately set.
    override public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        if self.sceneController.sceneData.openedProject.loaded {
            self.sceneController.pushCommand(command: GetProjectClose())
            self.sceneController.pushCommand(command: GetProjectDelete(projectID: self.projectID))
            completion(true, false, nil)
        } else {
            super.execute(completion: completion)
        }
    }
    
    /// Handles a valid response from the RCNode server after successfully deleting a project.
    override internal func validResponseAction(parsedResponse _: HTTPResponseParser, completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        DispatchQueue.main.async {
            let projectName = self.sceneController.sceneData.projectGUIDs.first(where: { $0.key == self.projectID })
            if projectName != nil {
                self.sceneController.sceneData.projectList.removeValue(forKey: projectName!.key)
                self.sceneController.sceneData.projectGUIDs.removeValue(forKey: projectName!.key)
            }
        }
        completion(true, false, nil)
    }
}
