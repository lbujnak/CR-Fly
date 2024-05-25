import SwiftUI

/**
 `GetProjectTasks` is a command derived from `ProjectCommand` that is specifically designed to retrieve the statuses of multiple tasks associated with a project on a RealityCapture node (RCNode). It sends a GET request to the RCNode's API endpoint to fetch the current states of specified tasks.
 
 The command plays a crucial role in applications that require detailed monitoring and management of task executions within projects, especially in environments where task statuses directly influence workflow decisions.
 */
public class GetProjectTasks: ProjectCommand {
    /// Reference to the `ViewController` responsible for managing navigation, presentation of different views within the application and displaying errors.
    private let viewController = CRFly.shared.viewController
    
    /// Initializes a new instance of the `GetProjectTasks` command with a specified array of task IDs.
    public init(tasks: [String] = []) {
        let urlEncodedArray = tasks.map { element in
            return element.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        }
        let joinedString = urlEncodedArray.count > 0 ? "?taskIDs=\(urlEncodedArray.joined(separator: ","))" : ""
        
        let structure = Structure(path: "/project/tasks\(joinedString)", method: .get, dataOutputType: .json3D, acceptStatusCode: 200, errorTitle: "Error Getting RCNode Project Tasks Statuses")
        super.init(structure: structure, requestedProjectState: .opened, executionDisableInteraction: false)
    }
    
    /// Overrides the base execute command method to retrieve the status of specified tasks from the RCNode.
    override public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        if self.sceneController.sceneData.openedProject.waitingOnTask.isEmpty {
            completion(true, false, nil)
        } else {
            super.execute(completion: completion)
        }
    }
    
    /// Processes the HTTP response upon successful communication with the RCNode, updating task statuses accordingly.
    override internal func validResponseAction(parsedResponse: HTTPResponseParser, completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        let json3DData = parsedResponse.bodyTo3DJSON()
        for task in json3DData! {
            guard let taskID = task["taskID"] as? String,
                  let timeStart = task["timeStart"] as? Int,
                  let timeEnd = task["timeEnd"] as? Int,
                  let state = task["state"] as? String,
                  let errorCode = task["errorCode"] as? Int,
                  let errorMessage = task["errorMessage"] as? String
            else {
                completion(false, false, ("Error Getting RCNode Project Tasks Statuses", "The response from RCNode was invalid. The structure of the response does not align with the expected API format."))
                return
            }
            
            let taskData = self.sceneController.sceneData.openedProject.waitingOnTask[taskID]
            var taskStatus = taskData?.1 ?? SceneProjectInfo.TaskStatus(taskName: "RealityCaptureTask", taskDescription: "Task started in RealityCapture")
            
            DispatchQueue.main.async {
                taskStatus.taskTimeStart = timeStart
                taskStatus.taskTimeEnd = timeEnd
                taskStatus.taskState = state
                
                self.sceneController.sceneData.openedProject.waitingOnTask[taskID] = (taskData == nil ? nil : taskData!.0,taskStatus)
                
                if state == "finished" || state == "failed" {
                    if state == "finished" {
                        if taskData?.0 != nil {
                            self.sceneController.pushCommand(command: taskData!.0!)
                        }
                    } else {
                        self.sceneController.pushCommand(command: GetProjectClearTasks(tasks: [taskID]))
                        self.viewController.showSimpleAlert(title: "Error Executing RCNode Task", msg: Text("Task: \(taskStatus.taskName), failed with error: \(errorCode). \(errorMessage)"))
                    }
                    self.sceneController.sceneData.openedProject.waitingOnTask.removeValue(forKey: taskID)
                }
            }
        }
        completion(true, false, nil)
    }
}
