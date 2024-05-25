import Foundation

/**
 `HTTPResponseParser` is a class designed to parse raw HTTP response data into a structured format, encapsulating the status code, headers, and body of the response. It provides utility methods for converting the body to various JSON structures, catering to different data handling requirements.
 
 - Note: The initializer and methods assume the response data is UTF-8 encoded. If parsing fails at any stage, the initializer will return nil, making this class safe against malformed HTTP responses.
 */
public class HTTPResponseParser {
    ///  An integer representing the HTTP status code of the response.
    public let statusCode: Int
    
    /// A dictionary containing all the HTTP header fields of the response, parsed as key-value pairs.
    public let headers: [String: String]
    
    /// A `Data` object containing the body of the response, which can be further processed or converted to other formats.
    public let body: Data
    
    /// Attempts to initialize an `HTTPResponseParser` by parsing the provided raw data. If the data does not conform to expected HTTP response structure, it returns `nil`.
    public init?(data: Data) {
        guard let responseString = String(data: data, encoding: .utf8),
              let rangeOfDoubleNewLine = responseString.range(of: "\r\n\r\n")
        else {
            return nil
        }
        
        let headerString = String(responseString[..<rangeOfDoubleNewLine.lowerBound])
        let bodyString = String(responseString[rangeOfDoubleNewLine.upperBound...])
        self.body = Data(bodyString.utf8)
        
        let lines = headerString.components(separatedBy: "\r\n")
        guard lines.count > 0 else { return nil }
        
        let statusLine = lines[0]
        self.headers = lines.dropFirst().reduce(into: [String: String]()) { result, line in
            let parts = line.components(separatedBy: ": ")
            if parts.count == 2 {
                result[parts[0]] = parts[1]
            }
        }
        
        // Extract status code from the status line
        let statusLineComponents = statusLine.components(separatedBy: " ")
        guard statusLineComponents.count >= 3, let statusCode = Int(statusLineComponents[1]) else { return nil }
        self.statusCode = statusCode
    }
    
    /// Tries to deserialize the response body into a 1-dimensional array of strings (assuming the body is JSON formatted).
    public func bodyTo1DJSON() -> [String]? {
        try? JSONSerialization.jsonObject(with: self.body, options: []) as? [String]
    }
    
    /// Tries to deserialize the response body into a dictionary of key-value pairs.
    public func bodyTo2DJSON() -> [String: Any]? {
        try? JSONSerialization.jsonObject(with: self.body, options: []) as? [String: Any]
    }
    
    /// Tries to deserialize the response body into an array of dictionaries, each representing a JSON object.
    public func bodyTo3DJSON() -> [[String: Any]]? {
        try? JSONSerialization.jsonObject(with: self.body, options: []) as? [[String: Any]]
    }
    
    /// Static method that attempts to parse provided data into a 2D JSON object.
    public static func parseTo2DJSON(data: Data?) -> [String: Any]? {
        var jsonData: [String: Any]?
        if data != nil {
            jsonData = try? JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
        }
        return jsonData
    }
    
    /// Static method that attempts to parse provided data into a 3D JSON object.
    public static func parseTo3DJSON(data: Data?) -> [[String: Any]]? {
        var jsonData: [[String: Any]]?
        if data != nil {
            jsonData = try? JSONSerialization.jsonObject(with: data!, options: []) as? [[String: Any]]
        }
        return jsonData
    }
}
