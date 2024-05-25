import Foundation
import Network
@testable import CR_Fly

final class TCPServer {
    private var listener: NWListener?
    private let port: UInt16
    
    init(port: UInt16) {
        self.port = port
    }
    
    func start() {
        do {
            listener = try NWListener(using: .tcp, on: NWEndpoint.Port(rawValue: port)!)
            listener?.newConnectionHandler = { newConnection in
                self.setupReceive(on: newConnection)
                newConnection.start(queue: .main)
            }
            listener?.start(queue: .main)
        } catch {
            print("Failed to start TCP server: \(error)")
        }
    }
    
    func stop() {
        listener?.cancel()
        listener = nil
    }
    
    private func setupReceive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                let message = String(decoding: data, as: UTF8.self)
                    
                if let filename = self.extractFilename(from: message) {
                    if let fileData = try? Data(contentsOf: DocURL(appDocDirPath: "HTTPTest", fileName: filename).getURL()) {
                        let response = Data("HTTP/1.1 200\r\nContent-Length: \(fileData.count)\r\n\r\n".utf8) + fileData
                        connection.send(content: response, completion: .contentProcessed({ sendError in
                            if let sendError = sendError {
                                print("Failed to send data: \(sendError)")
                            }
                        }))
                    } else {
                        let response = "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n\r\n"
                        connection.send(content: Data(response.utf8), completion: .contentProcessed({ sendError in
                            if let sendError = sendError {
                                print("Failed to send 404 response: \(sendError)")
                            }
                        }))
                    }
                } else {
                    connection.send(content: data, completion: .contentProcessed({ sendError in
                        if let sendError = sendError {
                            print("Failed to send data: \(sendError)")
                        }
                    }))
                }
            }
            if !isComplete {
                self.setupReceive(on: connection)
            }
        }
    }
        
    private func extractFilename(from message: String) -> String? {
        guard message.starts(with: "GET") else { return nil }
        let lines = message.split(separator: "\r\n")
        guard let requestLine = lines.first else { return nil }
        let components = requestLine.split(separator: " ")
        guard components.count >= 2 else { return nil }
        
        let filename = String(components[1].dropFirst())
        return filename.contains(".txt") ? filename : nil
    }
}
