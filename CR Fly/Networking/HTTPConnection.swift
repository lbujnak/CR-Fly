import Foundation
import Network

/**
 `HTTPConnection` manages network communication using the low-level networking API provided by Apple's Network framework. It supports operations like sending requests, uploading files, and downloading content by managing an `NWConnection` object.
 
 - Usage:
     - Initialize `HTTPConnection` with server details.
     - Use all public methods to communicate with server.
     - Monitor connection state changes to handle retries and reconnections.
     - Manage uploads and downloads of files for applications requiring direct file transfer capabilities.
 */
public class HTTPConnection {
    /// Holds all relevant data for establishing a connection, such as the target host, port, and network parameters required to configure the connection.
    public struct HTTPConnectionData {
        /// The hostname or IP address of the server for the connection.
        public let host: String
        
        /// The port number on the server to which the connection should be made.
        public let port: UInt16
        
        /// Network parameters that include protocol configurations and security settings for the connection.
        public let params: NWParameters
    }
    
    /// Represents the various states of an HTTP connection lifecycle.
    public enum HTTPConnectionState {
        /// The connection is active and data can be transmitted.
        case connected
        
        /// The connection is not active, no data can be transmitted.
        case disconnected
        
        /// The connection was active but has been unexpectedly lost.
        case lost
        
        /// Initial state when the connection is setting up.
        case started
    }
    
    /// Stores reference for `HTTPConnectionData` struct.
    private var connectionData: HTTPConnectionData
    
    /// An `NWConnection` instance that manages the underlying network communication.
    private var connection: NWConnection
    
    /// The current state of the connection, indicating if it's started, connected, disconnected, or lost.
    private var httpConnectionState: HTTPConnectionState = .started
    
    /// A continuation used in init to resume operation once the connection state changes to ready or fails.
    private var connectionReadyContinuation: CheckedContinuation<Void, Error>?
    
    /// A flag to indicate whether a file send operation should be canceled.
    private var sendFileCancelRequest: Bool = false
    
    /// A flag to indicate whether a file receive operation should be canceled.
    private var receiveFileCancelRequest: Bool = false
    
    /// Indicates whether a connection restart has been initiated.
    private var restartConnectionStarted: Bool = false
    
    /// A list of observers that are notified when the connection state changes.
    private var stateObservers: [HTTPConnectionStateObserver] = []
    
    /// A property that stores the last state notification of an HTTP connection.
    private var lastStateNotification: HTTPConnectionState? = nil
    
    /// A property that determines whether the connection should restart on `cancel()`.
    private var restartOnCancel: Bool = false
    
    /// Initializes a new HTTP connection with specified host, port, and network settings.
    public init(host: String, port: UInt16, connectionTimeout: Int, keepAlive: Bool) async throws {
        let options = NWProtocolTCP.Options()
        options.connectionTimeout = connectionTimeout
        options.enableKeepalive = keepAlive
        let params = NWParameters(tls: nil, tcp: options)
        self.connectionData = HTTPConnectionData(host: host, port: port, params: params)
        self.connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!, using: params)
        
        self.connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                self.httpConnectionState = .connected
                self.connectionReadyResume()
            case let .failed(error):
                self.httpConnectionState = .lost
                self.restartConnection() // RCNode is closing connection when error occurs so we need to "manually" restart it
                self.connectionReadyResume(throwing: error)
            case let .waiting(error):
                self.httpConnectionState = .disconnected
                self.connectionReadyResume(throwing: error)
            case .cancelled:
                self.httpConnectionState = self.restartOnCancel ? .lost : .disconnected
                if self.restartOnCancel {
                    self.restartConnection()
                }
            default: break
            }
            self.notifyObserversStateChange()
        }
        self.connection.start(queue: .global())
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.connectionReadyContinuation = continuation
        }
    }
    
    /// Resumes the `connectionReadyContinuation` with either a successful completion or an error. If the `connectionReadyContinuation` is not `nil`, it will be resumed and then set to `nil` to prevent multiple resumptions.
    private func connectionReadyResume(throwing: (any Error)? = nil) {
        if self.connectionReadyContinuation != nil {
            if throwing != nil {
                self.connectionReadyContinuation!.resume(throwing: throwing!)
            } else {
                self.connectionReadyContinuation!.resume()
            }
            self.connectionReadyContinuation = nil
        }
    }
    
    /// Attempts to re-establish a previously lost or disconnected HTTP connection.
    private func restartConnection() {
        Task {
            self.connection = NWConnection(host: NWEndpoint.Host(self.connectionData.host), port: NWEndpoint.Port(rawValue: self.connectionData.port)!, using: self.connectionData.params)
            
            self.connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    self.httpConnectionState = .connected
                case .failed:
                    self.httpConnectionState = .lost
                    self.restartConnection()
                case .waiting:
                    self.httpConnectionState = .disconnected
                case .cancelled:
                    if self.restartOnCancel {
                        self.httpConnectionState = .lost
                        self.restartConnection()
                    } else {
                        self.httpConnectionState = .disconnected
                    }
                default: break
                }
                
                self.notifyObserversStateChange()
            }
            self.connection.start(queue: .global())
        }
    }
    
    /// Cleanly closes or forcibly terminates the active network connection.
    public func terminateConnection(tryToRestart: Bool = false) {
        self.restartOnCancel = tryToRestart
        self.connection.cancel()
    }
    
    /// Returns `HTTPConnectionState` indicating the current state of the connection.
    public func getHttpConnectionState() -> HTTPConnectionState {
        self.httpConnectionState
    }
    
    /// Adds an observer to the list that will be notified on connection state changes.
    public func addStateChangeObserver(observer: HTTPConnectionStateObserver) {
        self.stateObservers.append(observer)
        observer.observeConnection(newState: self.httpConnectionState)
    }
    
    /// Removes an observer from the list.
    public func removeStateChangeObserer(observer: HTTPConnectionStateObserver) {
        if let index = stateObservers.firstIndex(where: { $0.getUniqueId() == observer.getUniqueId() }) {
            self.stateObservers.remove(at: index)
        }
    }
    
    /// Notifies all registered observers of the current connection state.
    private func notifyObserversStateChange() {
        if self.lastStateNotification == nil || self.httpConnectionState != self.lastStateNotification! {
            for observer in self.stateObservers {
                observer.observeConnection(newState: self.httpConnectionState)
            }
            self.lastStateNotification = self.httpConnectionState
        }
    }
    
    /// Sends an `HTTPRequest` and returns the server's response.
    public func send(request: HTTPRequest) async throws -> Data {
        var httpRequest = "\(request.method.rawValue) \(request.urlPath) HTTP/1.1\r\n"
        for (key, value) in request.headers {
            httpRequest += "\(key): \(value)\r\n"
        }
        httpRequest += "\r\n"
        
        if let body = request.body {
            httpRequest += body
        }
        
        try await self.sendAsync(content: Data(httpRequest.utf8))
        let data = try await receiveAllData()
        
        return data
    }
    
    /// Sends a file to the server with progress updates.
    public func sendFile(request: HTTPRequest, fileURL: DocURL, byteUploadedUpdate: ((UInt) -> Void)? = nil) async throws -> Data {
        guard let fileSize = try fileURL.getAttributesOfItem()[.size] as? Int else {
            throw NSError(domain: "HTTPConnection", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not determine file size."])
        }
        
        self.sendFileCancelRequest = false
        
        var httpRequest = "\(request.method.rawValue) \(request.urlPath) HTTP/1.1\r\n"
        for (key, value) in request.headers {
            httpRequest += "\(key): \(value)\r\n"
        }
        httpRequest += "Content-Length: \(fileSize)\r\n\r\n"
        
        let fileHandle = try FileHandle(forReadingFrom: fileURL.getURL())
        defer {
            try? fileHandle.close()
        }
        
        try await self.sendAsync(content: Data(httpRequest.utf8))
        
        var bytesToSend = fileSize
        while bytesToSend > 0 {
            if self.sendFileCancelRequest {
                self.sendFileCancelRequest = false
                try fileHandle.close()
                
                self.terminateConnection(tryToRestart: true)
                throw NSError(domain: "HTTPConnection", code: 2, userInfo: [NSLocalizedDescriptionKey: "Upload was cancelled."])
            }
            
            let chunkSize = min(bytesToSend, 65536)
            let chunkData = fileHandle.readData(ofLength: chunkSize)
            bytesToSend -= chunkData.count
            
            try await self.sendAsync(content: chunkData)
            if byteUploadedUpdate != nil {
                byteUploadedUpdate!(UInt(chunkSize))
            }
        }
        
        let responseData = try await receiveAllData()
        return responseData
    }
    
    /// Signals to cancel the ongoing file transmission. This method sets a flag that indicates any ongoing file send operation should be stopped.
    public func sendFileCancel() {
        self.sendFileCancelRequest = true
    }
    
    /// Downloads a file from the server and saves it to the specified directory.
    public func downloadFile(request: HTTPRequest, dirURL: DocURL, fileName: String, byteDownloadUpdate: ((UInt) -> Void)? = nil) async throws -> Data {
        var httpRequest = "\(request.method.rawValue) \(request.urlPath) HTTP/1.1\r\n"
        for (key, value) in request.headers {
            httpRequest += "\(key): \(value)\r\n"
        }
        httpRequest += "\r\n"
        
        if let body = request.body {
            httpRequest += body
        }
        
        self.receiveFileCancelRequest = false
        
        try await self.sendAsync(content: Data(httpRequest.utf8))
        let data = try await receiveAllData(toFileWithURL: dirURL.appendFile(fileName: fileName), byteDownloadUpdate: byteDownloadUpdate)
        return data
    }
    
    /// Signals to cancel the ingoing file transmission. This method sets a flag that indicates any ingoing file send operation should be stopped.
    public func downloadFileCancel() {
        self.receiveFileCancelRequest = true
    }
    
    /// Asynchronously sends data over the network connection. This method leverages Swift's concurrency model to handle network data sending operations.
    private func sendAsync(content: Data) async throws {
        if self.httpConnectionState != .connected {
            throw NWError.posix(.ENOTCONN)
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.connection.send(content: content, completion: .contentProcessed { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }
    
    /// Asynchronously receives data from the network connection, handling both data accumulation and file writing if specified.
    private func receiveAllData(toFileWithURL: DocURL? = nil, byteDownloadUpdate: ((UInt) -> Void)? = nil) async throws -> Data {
        var fileHandle: FileHandle? = nil
        
        if toFileWithURL != nil {
            if toFileWithURL!.existsItem() {
                try toFileWithURL!.removeItem()
            }
            try toFileWithURL!.createItem(withIntermediateDirectories: true)
            fileHandle = try FileHandle(forWritingTo: toFileWithURL!.getURL())
        }
        
        defer {
            if fileHandle != nil {
                try? fileHandle!.close()
            }
        }
        
        var accumulatedData = Data()
        var headersEndFound = false
        var remainingLengthToReceive = Int.max
        
        var receivedData = 0
        
        while true {
            if self.receiveFileCancelRequest, toFileWithURL != nil {
                self.receiveFileCancelRequest = false
                try fileHandle!.close()
                try toFileWithURL!.removeItem()
                
                self.restartConnection()
                throw NSError(domain: "HTTPConnection", code: 2, userInfo: [NSLocalizedDescriptionKey: "Download was cancelled."])
            }
            
            let data = try await receiveAsync(maximumLength: 65536)
            if !headersEndFound {
                accumulatedData.append(data)
                
                if let headersEndRange = accumulatedData.range(of: Data("\r\n\r\n".utf8)) {
                    headersEndFound = true
                    let headersData = accumulatedData.subdata(in: 0 ..< headersEndRange.lowerBound)
                    let bodyDataStartIndex = headersEndRange.upperBound
                    
                    if let contentLengthValue = parseContentLength(from: headersData) {
                        remainingLengthToReceive = contentLengthValue - (accumulatedData.count - bodyDataStartIndex)
                    }
                    
                    if remainingLengthToReceive <= 0 {
                        return accumulatedData
                    }
                    
                    if fileHandle != nil {
                        let bodyData = accumulatedData.subdata(in: bodyDataStartIndex ..< accumulatedData.count)
                        fileHandle!.write(bodyData)
                        if byteDownloadUpdate != nil {
                            byteDownloadUpdate!(UInt(bodyData.count))
                        }
                        
                        accumulatedData = headersData
                        accumulatedData.append(Data("\r\n\r\n".utf8))
                    }
                }
            } else {
                receivedData += data.count
                if fileHandle == nil {
                    accumulatedData.append(data)
                } else {
                    fileHandle!.write(data)
                    if byteDownloadUpdate != nil {
                        byteDownloadUpdate!(UInt(data.count))
                    }
                }
                remainingLengthToReceive -= data.count
                if remainingLengthToReceive <= 0 {
                    break
                }
            }
        }
        return accumulatedData
    }
    
    /// A helper method that facilitates the asynchronous reception of data from the network connection.
    private func receiveAsync(maximumLength: Int) async throws -> Data {
        if self.httpConnectionState != .connected {
            throw NWError.posix(.ENOTCONN)
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.connection.receive(minimumIncompleteLength: 1, maximumLength: maximumLength) { data, _, isComplete, error in
                
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let data, !data.isEmpty {
                    continuation.resume(returning: data)
                } else if isComplete {
                    continuation.resume(returning: Data())
                }
            }
        }
    }
    
    /// Parses the `Content-Length` header from the received HTTP headers to determine the length of the incoming data payload.
    private func parseContentLength(from data: Data) -> Int? {
        guard let headersString = String(data: data, encoding: .utf8) else { return nil }
        let headers = headersString.split(separator: "\r\n")
        for header in headers {
            let headerParts = header.split(separator: ":").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if headerParts.count == 2, headerParts[0].lowercased() == "content-length", let length = Int(headerParts[1]) {
                return length
            }
        }
        return nil
    }
}
