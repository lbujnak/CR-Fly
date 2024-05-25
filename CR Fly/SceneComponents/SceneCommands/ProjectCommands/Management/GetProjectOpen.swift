import Foundation

/**
 `GetProjectOpen` is a specialized command class derived from `ProjectCommand` designed to handle the opening of a specific project on a RealityCapture node (RCNode). It issues a GET request to the RCNode API to open a project by its unique identifier (GUID).
 
 The functionality ensures that the correct project context is set up before performing any project-specific operations, maintaining the integrity of the session-specific data and interactions.
 */
public class GetProjectOpen: ProjectCommand {
    /// The GUID of the project to be opened.
    private let projectID: String
    
    /// Initializes a new instance of the `GetProjectOpen` command with specified project details.
    public init(projectID: String) {
        self.projectID = projectID
        
        let structure = Structure(path: "/project/open?guid=\(projectID)", method: .get, dataOutputType: .none, acceptStatusCode: 200, errorTitle: "Error Opening RCNode Project")
        super.init(structure: structure, requestedProjectState: .none, executionDisableInteraction: true)
    }
    
    /// Overrides the base execute command method to open project and handle the response to ensure the project context is appropriately set.
    override public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        if self.sceneController.sceneData.openedProject.loaded {
            let projectName = self.sceneController.sceneData.projectGUIDs.first(where: { $0.value == self.projectID })
            if projectName == nil {
                completion(false, false, ("Error Opening RCNode Project", "Project name could not be found in project list."))
                return
            }
            
            if self.sceneController.sceneData.openedProject.name != projectName!.key {
                self.sceneController.pushCommand(command: GetProjectClose())
                self.sceneController.pushCommand(command: GetProjectOpen(projectID: self.projectID))
            }
            completion(true, false, nil)
        } else {
            super.execute(completion: completion)
        }
    }
    
    /// Handles a valid response from the RCNode server after successfully opening a project.
    override internal func validResponseAction(parsedResponse: HTTPResponseParser, completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        let projectName = self.sceneController.sceneData.projectGUIDs.first(where: { $0.value == self.projectID })
        if projectName == nil {
            completion(false, false, ("Error Opening RCNode Project", "Project name could not be found in project list."))
            return
        }
        
        DispatchQueue.main.async {
            self.sceneController.sceneData.openedProject = SceneProjectInfo(loaded: true, name: projectName!.key, sessionID: parsedResponse.headers["Session"])
            self.sceneController.pushCommand(command: CreateTemplateFiles())
            self.sceneController.loadSavedModels()
        }
        completion(true, false, nil)
    }
}
