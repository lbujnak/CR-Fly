import Foundation

/**
 `GetNodeStatus` is a command class that extends `RCNodeCommand` to handle the retrieval of the status from a RealityCapture node (RCNode). It sends a GET request to the RCNode's API endpoint to retrieve its current operational status, including session management and availability.
 
 This command is integral to maintaining an up-to-date view of the RCNode's status within applications that interact with RealityCapture technology, particularly in distributed or remote environments.
 */
public class GetNodeStatus: RCNodeCommand {
    /// Sets up the command with the predefined request structure tailored to querying the RCNode's status. It's geared specifically towards endpoints that respond with JSON data representing the node's status.
    public init() {
        let structure = Structure(path: "/node/status", method: .get, dataOutputType: .json2D, acceptStatusCode: 200, errorTitle: "Error Getting RCNode Status")
        super.init(structure: structure)
    }
    
    /// Processes the HTTP response upon successful communication with the RCNode.
    override func validResponseAction(parsedResponse: HTTPResponseParser, completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        let jsonData = parsedResponse.bodyTo2DJSON()
        guard let status = jsonData!["status"] as? String,
              let activeSessions = jsonData!["activeSessions"] as? Int,
              let maxSessions = jsonData!["maxSessions"] as? Int
        else {
            completion(false, false, ("Error Getting RCNode Status", "The response from RCNode was invalid. The structure of the response does not align with the expected API format."))
            return
        }
        
        DispatchQueue.main.async {
            if self.sceneController.nodeStatus != status {
                self.sceneController.nodeStatus = status
            }
            
            if self.sceneController.availableSessions != maxSessions - activeSessions {
                self.sceneController.availableSessions = maxSessions - activeSessions
            }
        }
        
        completion(true, false, nil)
    }
}
