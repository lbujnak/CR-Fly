import Foundation

/**
 `GetNodeProjects`is a command class that extends `RCNodeCommand` designed to fetch a list of projects from a RealityCapture Node (RCNode). It sends a GET request to the RCNode's API endpoint to retrieve project information including names, GUIDs, and timestamps.
 */
public class GetNodeProjects: RCNodeCommand {
    public init() {
        let structure = Structure(path: "/node/projects", method: .get, dataOutputType: .json3D, acceptStatusCode: 200, errorTitle: "Error Getting RCNode Project List")
        super.init(structure: structure)
    }
    
    /// Processes the HTTP response upon successful communication with the RCNode.
    override func validResponseAction(parsedResponse: HTTPResponseParser, completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        let json3DData = parsedResponse.bodyTo3DJSON()
        var newProjectList: [String: Int] = [:]
        var newGuidList: [String: String] = [:]
        
        for project in json3DData! {
            guard let name = project["name"] as? String,
                  let guid = project["guid"] as? String,
                  let timeStamp = project["timeStamp"] as? Int
            else {
                completion(false, false, ("Error Getting RCNode Project List", "The response from RCNode was invalid. The structure of the response does not align with the expected API format."))
                return
            }
            newProjectList[name] = timeStamp
            newGuidList[name] = guid
        }
        
        if newProjectList.count == 0 {
            newProjectList["<none>"] = Int.max
        }
        
        DispatchQueue.main.async {
            self.sceneController.sceneData.projectList = newProjectList
            self.sceneController.sceneData.projectGUIDs = newGuidList
        }
        
        completion(true, false, nil)
    }
}
