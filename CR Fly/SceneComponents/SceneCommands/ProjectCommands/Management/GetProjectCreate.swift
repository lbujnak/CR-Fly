import Foundation

/**
 `GetProjectCreate` is a command class derived from `ProjectCommand` designed to handle the creation of a new project on a RealityCapture node (RCNode). It sends a GET request to the RCNode's API to initiate the creation of a project with a specified name.
 
 The command ensures that a new project context is accurately established before any project-specific operations commence, maintaining operational integrity and data coherence within the application.
 */
public class GetProjectCreate: ProjectCommand {
    /// The name of the project to be created.
    private let projectName: String
    
    /// Initializes a new instance of the `GetProjectCreate` command with a specified project name.
    public init(projectName: String) {
        self.projectName = projectName
        
        let structure = Structure(path: "/project/create", method: .get, dataOutputType: .none, acceptStatusCode: 201, errorTitle: "Error Creating RCNode Project")
        super.init(structure: structure, requestedProjectState: .closed, executionDisableInteraction: true)
    }
    
    /// Handles a valid response from the RCNode server after successfully creating a project.
    override internal func validResponseAction(parsedResponse: HTTPResponseParser, completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        
        var createProjectName = ""
        if self.projectName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) == nil {
            createProjectName = "cr_fly_\(String(describing: Date().timeIntervalSince1970))"
        }
        
        let created = SceneProjectInfo(loaded: true, name: (createProjectName != "" ? createProjectName : self.projectName), sessionID: parsedResponse.headers["Session"])
        
        DispatchQueue.main.async {
            self.sceneController.sceneData.openedProject = created
        }
        self.sceneController.pushCommand(command: GetProjectSave(projectName: (createProjectName != "" ? createProjectName : self.projectName)))
        self.sceneController.pushCommand(command: CreateTemplateFiles())
        
        completion(true, false, nil)
    }
}
