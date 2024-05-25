import Foundation

/**
 `GetProjectDataList` is a command class derived from `ProjectCommand` that facilitates fetching the list of files from a specified folder within a project on a RealityCapture node (RCNode). It sends a GET request to the RCNode's API endpoint to obtain the list of files present in either the 'data' or 'output' folder of the project.
 
 The command is crucial for applications that manage file-based workflows within projects, especially in environments where file management is a core function.
 */
public class GetProjectList: ProjectCommand {
    /// Enum defining the types of folders whose contents can be queried.
    public enum FolderType: String { case data, output }
    
    /// The folder from which to fetch the file list.
    private let folder: FolderType
    
    /// Initializes a new instance of the `GetProjectDataList` command with a specified folder type.
    public init(folder: FolderType = .data) {
        self.folder = folder
        let structure = Structure(path: "/project/list?folder=\(folder.rawValue)", method: .get, dataOutputType: .json1D, acceptStatusCode: 200, errorTitle: "Error Getting RCNode Project File List")
        super.init(structure: structure, requestedProjectState: .opened, executionDisableInteraction: false)
    }
    
    /// Overrides the base execute command method to retrieve the file list from the specified folder.
    override public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        self.sceneController.sceneData.openedProject.projectUpdateState = self.folder == .data ? .fetchProjectInputList : .fetchProjectOutputList
        super.execute(completion: { v1, v2, v3 in
            DispatchQueue.main.async {
                self.sceneController.sceneData.openedProject.projectUpdateState = nil
            }
            completion(v1, v2, v3)
        })
    }
    
    /// Processes the HTTP response upon successful communication with the RCNode, updating the file list or handling data accordingly.
    override internal func validResponseAction(parsedResponse: HTTPResponseParser, completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        let jsonData = parsedResponse.bodyTo1DJSON()
        DispatchQueue.main.async {
            switch self.folder {
            case .data:
                self.sceneController.sceneData.openedProject.fileList = Set(jsonData!)
            case .output:
                self.sceneController.observeOutputFolder(files: jsonData!)
            }
        }
        
        completion(true, false, nil)
    }
}
