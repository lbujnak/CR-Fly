import Foundation

/**
 `ProjectCLICommand`  is a command class that extends `ProjectCommand` to handle CLI-specific commands that interact with the RealityCapture Node. This class uses `CLIStructure` to define and execute tasks related to project management via command line interfaces.
 
 - Usage: An instance of `ProjectCLICommand` can be created to execute a specific CLI command, handle its response, and potentially chain further commands based on the outcome. This is particularly useful in automated workflows where multiple CLI operations need to be coordinated.
 */
public class ProjectCLICommand: ProjectCommand {
    /**
     `CLIStructure` defines the parameters necessary for executing a CLI command related to project management in a RealityCapture Node.
     
     - Usage: `CLIStructure` is primarily used to set up commands that interface directly with a CLI, providing detailed task descriptions and subsequent actions upon completion.
     */
    public struct CLIStructure {
        /// The endpoint path for the CLI request.
        public let path: String
        
        /// The HTTP method to be used for the request (e.g., GET, POST).
        public let method: HTTPRequest.Method
        
        /// The body data for the request, formatted as a JSON string if applicable.
        public let data: String?
        
        /// A string that provides a context-specific title for errors that may occur during the request.
        public let errorTitle: String
        
        /// A descriptive name for the task that this command represents.
        public let taskName: String
        
        /// A detailed description of what the task is supposed to achieve.
        public let taskDescription: String
        
        /// An optional `Command` to be executed upon successful completion of the CLI command.
        public let doWhenDone: Command?
        
        /// Constructs a `CLIStructure` with specified parameters for executing a CLI command. This structure encapsulates all necessary details to formulate and process the request properly, ensuring that the task is identified and described appropriately for logging and user feedback.
        public init(path: String, method: HTTPRequest.Method, data: String? = nil, errorTitle: String, taskName: String, taskDescription: String, doWhenDone: Command? = nil) {
            self.path = path
            self.method = method
            self.data = data
            self.errorTitle = errorTitle
            self.taskName = taskName
            self.taskDescription = taskDescription
            self.doWhenDone = doWhenDone
        }
    }
    
    /// An instance of `CLIStructure` containing the parameters for the CLI request.
    private let cliStructure: CLIStructure
    
    /// Initializes a `ProjectCLICommand` using a provided `CLIStructure`. This setup allows the command to be executed with specific parameters tailored to CLI operations within the RealityCapture Node.
    public init(cliStructure: CLIStructure) {
        self.cliStructure = cliStructure
        let structure = RCNodeCommand.Structure(path: cliStructure.path, method: cliStructure.method, dataOutputType: .json2D, acceptStatusCode: 202, errorTitle: cliStructure.errorTitle)
        super.init(structure: structure, requestedProjectState: .opened, executionDisableInteraction: false)
    }
    
    /// Processes the successful HTTP response from the CLI command execution. This method specifically checks for the expected 'taskID' in the JSON response to link the command result with subsequent actions defined in `CLIStructure`.
    override internal func validResponseAction(parsedResponse: HTTPResponseParser, completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        let jsonData = parsedResponse.bodyTo2DJSON()
        
        guard let status = jsonData!["taskID"] as? String
        else {
            completion(false, false, (self.cliStructure.errorTitle, "The response from RCNode was invalid. The structure of the response does not align with the expected API format."))
            return
        }
        
        let taskStatus = SceneProjectInfo.TaskStatus(taskName: self.cliStructure.taskName, taskDescription: self.cliStructure.taskDescription)
        
        DispatchQueue.main.async {
            self.sceneController.sceneData.openedProject.waitingOnTask[status] = (self.cliStructure.doWhenDone, taskStatus)
            completion(true, false, nil)
        }
    }
}
