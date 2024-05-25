import Foundation

/**
 `RCNodeCommand` is an abstract base class designed for executing network commands against a RealityCapture Node (RCNode). It manages the construction and execution of network requests, handling of responses, and parsing of data returned by the RCNode.
 
 - Usage: Subclasses of `RCNodeCommand` should override `validResponseAction` to implement specific response handling logic. This pattern allows for encapsulation of the HTTP communication logic while providing flexibility for command-specific processing.
 
 This approach maintains clean separation between network code and business logic, simplifying maintenance and testing.
 */
public class RCNodeCommand: Command {
    /**
     `DataOutputType` is an enumeration used within the `RCNodeCommand` class to specify the expected format of the response data from a network request. It aids in ensuring that the response handling logic is aligned with the data structure returned by the RCNode API.
     
     - The `DataOutputType` is utilized by `RCNodeCommand` to validate and parse the network response based on the expected data format. Depending on the operation being performed, the appropriate `DataOutputType` ensures that the parsing mechanism is prepared to handle the complexity of the data returned by the API.
     */
    public enum DataOutputType {
        /// Indicates that no specific data is expected in the response. This case is used for commands where the outcome is determined solely by the HTTP status code without any response body.
        case none
        
        /// Specifies that the response should be a single-dimensional JSON object, typically used for simple key-value pairs.
        case json1D
        
        /// Specifies that the response should be a two-dimensional JSON object, suitable for more complex information such as lists of objects or detailed object properties.
        case json2D
        
        /// Specifies that the response should be a three-dimensional JSON structure, often used for nested data that includes lists of objects where each object may itself contain other objects or lists.
        case json3D
    }
    
    /// `Structure` is struct that defines the essential components of the network request.
    public struct Structure {
        /// A  string representing the URL path to the RCNode endpoint.
        public let path: String
        
        /// An `HTTPRequest.Method` enum value specifying the HTTP method (GET, POST, etc.).
        public let method: HTTPRequest.Method
        
        /// An optional string containing any data payload to be sent with the request.
        public let data: String?
        
        /// An enum `DataOutputType` indicating the expected format of the response data (none, json1D, json2D, json3D).
        public let dataOutputType: DataOutputType
        
        /// An integer representing the HTTP status code that indicates a successful response.
        public let acceptStatusCode: Int
        
        /// A string used for error handling, providing a context-specific title for any errors that occur during the command execution.
        public let errorTitle: String
        
        /**
         Initializes a new instance of the `Structure` struct, which defines the essential properties for an HTTP request within the `RCNodeCommand` system.
         
         - Parameter path: A `String` specifying the endpoint path of the RCNode API. This path is appended to the base URL of the RCNode server to form the full URL for the request.
         - Parameter method: The HTTP request method (e.g., `.get`, `.post`) used for the API call, represented by the `HTTPRequest.Method` enumeration.
         - Parameter data: An optional `String` containing the body data to be sent with the request. This is typically used with methods like `POST` or `PUT` where the request body is necessary.
         - Parameter dataOutputType: An enumeration value of type `DataOutputType` that specifies the expected format of the response data. This helps in configuring the response handling logic appropriately.
         - Parameter acceptStatusCode: An `Int` representing the expected HTTP status code that indicates a successful response. Any deviation from this code is treated as an error condition.
         - Parameter errorTitle: A `String` providing a descriptive title for the error. This title is used in error messages to provide context about the type of error that occurred during the API call.
         
         - Usage: The initializer is used to create a structured definition for an HTTP request, encapsulating all the necessary parameters that define how the request should be made and how the response should be handled. It is used when constructing instances of `RCNodeCommand` or its subclasses, ensuring that each command has a clear and well-defined request structure.
         */
        public init(path: String, method: HTTPRequest.Method, data: String? = nil, dataOutputType: DataOutputType, acceptStatusCode: Int, errorTitle: String) {
            self.path = path
            self.method = method
            self.data = data
            self.dataOutputType = dataOutputType
            self.acceptStatusCode = acceptStatusCode
            self.errorTitle = errorTitle
        }
    }
    
    /// Reference to an instance of `SceneController` that manages broader scene-related operations.
    let sceneController = CRFly.shared.sceneController as! RCNodeController
    
    /// Defines the specifics of the HTTP request made by this command.
    private let structure: Structure
    
    /**
     Initializes a new instance of the `RCNodeCommand` class, which provides a framework for executing commands related to RCNode operations.
     
     - Parameter structure: An instance of the `Structure` struct that defines the specifics of the HTTP request to be made by this command. The structure includes details such as the API endpoint, HTTP method, expected output type, and error handling specifics.
     
     - Description: This initializer sets up a new command with a predefined HTTP request structure, allowing it to perform specific tasks related to the RealityCapture Node (RCNode). It configures the command with all the necessary information to construct and execute an HTTP request, handle the response, and process any resulting data or errors.
     
     - Usage: The `RCNodeCommand` is designed to be subclassed by specific commands that implement their own response handling logic. Each subclass can use this initializer to set up the basic request structure, while implementing additional logic in methods such as `execute` or `validResponseAction`.
     */
    public init(structure: Structure) {
        self.structure = structure
    }
    
    /**
     Executes the command asynchronously. It constructs the HTTP request based on the `structure`, sends it, and processes the response.
     - The method leverages Swift's concurrency model (`Task`) to perform network operations.
     - Upon receiving a response, it validates the status code and the data format based on `dataOutputType`.
     - Calls `validResponseAction(parsedResponse:completion:)` if the response is valid, or handles errors by terminating the connection and reporting the failure.
     */
    public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        Task {
            do {
                let request = self.sceneController.constructHTTPRequest(path: self.structure.path, method: self.structure.method, data: self.structure.data)
                let data = try await self.sceneController.nodeConnection?.send(request: request)
                
                guard let data else {
                    completion(false, true, (self.structure.errorTitle, "Connection with RealityCapture is not established."))
                    return
                }
                
                if let parsedResponse = HTTPResponseParser(data: data) {
                    let hasExpectedOutputType =
                    (self.structure.dataOutputType == .none ||
                     (self.structure.dataOutputType == .json1D && parsedResponse.bodyTo1DJSON() != nil) ||
                     (self.structure.dataOutputType == .json2D && parsedResponse.bodyTo2DJSON() != nil) ||
                     (self.structure.dataOutputType == .json3D && parsedResponse.bodyTo3DJSON() != nil))
                    
                    if parsedResponse.statusCode == self.structure.acceptStatusCode, hasExpectedOutputType {
                        self.validResponseAction(parsedResponse: parsedResponse, completion: completion)
                        return
                    }
                    
                    self.sceneController.nodeConnection?.terminateConnection()
                    completion(false, false, (self.structure.errorTitle, "The response from RCNode was invalid. Error: \(parsedResponse.bodyTo2DJSON()?["message"] ?? "Unknown")"))
                } else {
                    self.sceneController.nodeConnection?.terminateConnection()
                    completion(false, false, (self.structure.errorTitle, "An issue was encountered while parsing the response from RCNode. \(String(data: data, encoding: .utf8))"))
                }
            } catch {
                self.sceneController.nodeConnection?.terminateConnection()
                completion(false, true, (self.structure.errorTitle, "An issue occurred while sending the request, error: \(error.localizedDescription)"))
                return
            }
        }
    }
    
    /// Processes the HTTP response upon successful communication with the RCNode.
    internal func validResponseAction(parsedResponse _: HTTPResponseParser, completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        completion(true, false, nil)
    }
}
