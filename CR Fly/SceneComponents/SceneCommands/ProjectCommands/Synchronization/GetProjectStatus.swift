import Foundation

/**
 `GetProjectStatus` is a command class derived from `ProjectCommand` used for obtaining the current operational status of a project on a RealityCapture node (RCNode). It sends a GET request to the RCNode's API endpoint to fetch detailed status information about the project including its progress, errors, and operational flags.
 
 This command is crucial for applications that require real-time tracking of project status and is essential for systems that manage or automate workflows in environments using RealityCapture technology.
 */
public class GetProjectStatus: ProjectCommand {
    /// Initializes a new instance of the `GetProjectStatus` command.
    public init() {
        let structure = Structure(path: "/project/status", method: .get, dataOutputType: .json2D, acceptStatusCode: 200, errorTitle: "Error Getting RCNode Project Status")
        super.init(structure: structure, requestedProjectState: .opened, executionDisableInteraction: false)
    }
    
    /// Processes the HTTP response upon successful communication with the RCNode.
    override internal func validResponseAction(parsedResponse: HTTPResponseParser, completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        let jsonData = parsedResponse.bodyTo2DJSON()
        guard let restarted = jsonData!["restarted"] as? Bool,
              let progress = jsonData!["progress"] as? Double,
              let timeTotal = jsonData!["timeTotal"] as? Double,
              let timeEstimation = jsonData!["timeEstimation"] as? Double,
              let errorCode = jsonData!["errorCode"] as? Int,
              let changeCounter = jsonData!["changeCounter"] as? Int,
              let processID = jsonData!["processID"] as? Int
        else {
            DispatchQueue.main.async {
                self.sceneController.projectUnload()
            }
            completion(false, false, ("Error Getting RCNode Project Status", "The response from RCNode was invalid. The structure of the response does not align with the expected API format."))
            return
        }
        
        DispatchQueue.main.async {
            self.sceneController.sceneData.openedProject.restarted = restarted
            self.sceneController.sceneData.openedProject.progress = progress
            self.sceneController.sceneData.openedProject.timeTotal = timeTotal
            self.sceneController.sceneData.openedProject.timeEstimation = timeEstimation
            self.sceneController.sceneData.openedProject.errorCode = errorCode
            self.sceneController.sceneData.openedProject.processID = processID
            
            if self.sceneController.sceneData.openedProject.changeCounter != changeCounter, self.sceneController.sceneData.mediaUploadState == nil, self.sceneController.sceneData.openedProject.waitingOnTask.count == 0 {
                
                self.sceneController.pushCommand(command: GetProjectList())
                self.sceneController.pushCommand(command: EvaluateProjectInfo())
                self.sceneController.sceneData.openedProject.changeCounter = changeCounter
            }
            completion(true, false, nil)
        }
    }
}
