import Foundation

/**
 `HTTPRequest` encapsulates all the necessary components of an HTTP request including the URL path, HTTP method, headers, and an optional body. It is designed to provide a convenient way to construct and manage the elements of a request before sending it to a server.
 
 - Usage: This struct is particularly useful for networking tasks where HTTP requests are required. It helps in organizing and maintaining the structure of requests, making the code cleaner and easier to manage.
 
 - Note: The HTTPRequest struct does not handle sending the request to a server itself; it is used for organizing and configuring the components of a request. Networking tasks such as sending the request and handling the response should be managed by other parts of your application architecture, possibly using URLSession or similar APIs.
 */
public struct HTTPRequest {
    /** `Method` is a nested enum within `HTTPRequest` that defines the types of HTTP methods supported by the request struct.
    - Each case of the `Method` enum also has a raw value corresponding to the HTTP method string it represents (e.g., "GET", "POST").
     */
    public enum Method: String {
        /// Represents an HTTP GET request, used to retrieve data from a server.
        case get = "GET"
        
        /// Represents an HTTP POST request, used to send data to a server.
        case post = "POST"
    }
    
    /// A `String` representing the URL to which the request will be sent.
    public let urlPath: String
    
    /// An enumeration of type `Method` that defines the HTTP method used for the request, such as GET or POST.
    public let method: HTTPRequest.Method
    
    /// A dictionary of headers where each key-value pair represents a header field and its value. This allows for customization of the request headers for content type, authentication, and other necessary data.
    public let headers: [String: String]
    
    /// An optional `String` that contains the body of the request, used primarily for POST requests to send data to the server.
    public let body: String?
    
    /// Initializes a new `HTTPRequest` with specified parameters.
    public init(urlPath: String, method: Method, headers: [String: String] = [:], body: String? = nil) {
        self.urlPath = urlPath
        self.method = method
        self.headers = headers
        self.body = body
    }
}
