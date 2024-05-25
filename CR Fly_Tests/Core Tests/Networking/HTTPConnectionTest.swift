import XCTest
import Network
@testable import CR_Fly

final class HTTPConnectionTests: XCTestCase {
    static var server: TCPServer!
    
    override class func setUp() {
        super.setUp()
        
        server = TCPServer(port: 8080)
        server.start()
        sleep(1)
    }
    
    override class func tearDown() {
        server.stop()
        server = nil
        super.tearDown()
    }
    
    func testInitialization() async throws {
        do {
            let connection = try await HTTPConnection(host: "127.0.0.1", port: 8080, connectionTimeout: 10, keepAlive: true)
            XCTAssertEqual(connection.getHttpConnectionState(), .connected)
        } catch {
            XCTFail("Initialization failed with error: \(error)")
        }
    }
    
    func testTerminateConnection() async throws {
        do {
            let connection = try await HTTPConnection(host: "127.0.0.1", port: 8080, connectionTimeout: 10, keepAlive: true)
            let observer = MockObserver()
            connection.addStateChangeObserver(observer: observer)
            let expectation = XCTestExpectation(description: "Connection should be disconnected")
            observer.onStateChange = { newState in
                if newState == .disconnected {
                    expectation.fulfill()
                }
            }
            connection.terminateConnection(tryToRestart: false)
            await fulfillment(of: [expectation], timeout: 5)
            XCTAssertEqual(connection.getHttpConnectionState(), .disconnected)
        } catch {
            XCTFail("Terminate connection failed with error: \(error)")
        }
    }
    
    func testTerminateConnectionWithRestart() async throws {
        do {
            let connection = try await HTTPConnection(host: "127.0.0.1", port: 8080, connectionTimeout: 10, keepAlive: true)
            let observer = MockObserver()
            connection.addStateChangeObserver(observer: observer)
            let expectation = XCTestExpectation(description: "Connection should be connected")
            observer.onStateChange = { newState in
                if newState == .connected {
                    expectation.fulfill()
                }
            }
            connection.terminateConnection(tryToRestart: true)
            await fulfillment(of: [expectation], timeout: 5)
            XCTAssertEqual(connection.getHttpConnectionState(), .connected)
        } catch {
            XCTFail("Terminate connection with restart failed with error: \(error)")
        }
    }
    
    func testSendRequest() async throws {
        do {
            let connection = try await HTTPConnection(host: "127.0.0.1", port: 8080, connectionTimeout: 10, keepAlive: true)
            let request = HTTPRequest(urlPath: "/", method: .get, headers: ["Content-Length": "0"])
            let response = try await connection.send(request: request)
            XCTAssertNotNil(response)
            XCTAssertEqual(String(data: response, encoding: .utf8), "GET / HTTP/1.1\r\nContent-Length: 0\r\n\r\n")
        } catch {
            XCTFail("Send request failed with error: \(error)")
        }
    }
    
    func testSendFileAndCancel() async throws {
        do {
            let file = DocURL(appDocDirPath: "HTTPTest", fileName: "upload.txt")
            let connection = try await HTTPConnection(host: "127.0.0.1", port: 8080, connectionTimeout: 10, keepAlive: true)
            let request = HTTPRequest(urlPath: "/", method: .post)
            var uploadedBytes: UInt = 0
            
            do {
                _ = try await connection.sendFile(request: request, fileURL: file) { bytesUploaded in }
                XCTFail("Expected sendFile to throw, but it did not.")
            } catch {
                XCTAssertEqual(error.localizedDescription, "The file “upload.txt” couldn’t be opened because there is no such file.")
            }
            try file.createItem(withIntermediateDirectories: true)
            try Data(count: 100000).write(to: file.getURL())
            
            let response = try await connection.sendFile(request: request, fileURL: file) { bytesUploaded in
                uploadedBytes += bytesUploaded
            }
            XCTAssertEqual(uploadedBytes, 100000)
            XCTAssertNotNil(response)
            XCTAssertEqual(String(data: response, encoding: .utf8), "POST / HTTP/1.1\r\nContent-Length: 100000\r\n\r\n\(String(data: Data(count: 100000), encoding: .utf8) ?? "")")
            
            do {
                _ = try await connection.sendFile(request: request, fileURL: file) { bytesUploaded in
                    connection.sendFileCancel()
                }
                XCTFail("Expected sendFile to throw, but it did not")
            } catch {
                XCTAssertEqual(error.localizedDescription, "Upload was cancelled.")
            }
            
            try file.removeItem()
        } catch {
            XCTFail("Send file failed with error: \(error)")
        }
    }
    
    func testDownloadFile() async throws {
        let fileDir = DocURL(appDocDirPath: "HTTPTest")
        let file = DocURL(appDocDirPath: "HTTPTest", fileName: "server.txt")
        let file2 = DocURL(appDocDirPath: "HTTPTest", fileName: "server-big.txt")
        try file.createItem()
        try file2.createItem()
        try Data(count: 100000).write(to: file.getURL())
        try Data(count: 500000).write(to: file2.getURL())
        
        do {
            let connection = try await HTTPConnection(host: "localhost", port: 8080, connectionTimeout: 10, keepAlive: true)
            var downloadedBytes: UInt = 0
            let request = HTTPRequest(urlPath: "/server.txt", method: .get, headers: ["Content-Length": "0"])
            let response = try await connection.downloadFile(request: request, dirURL: fileDir, fileName: "server_receive.txt", byteDownloadUpdate: { bytes in
                downloadedBytes += bytes
            })
            XCTAssertEqual(downloadedBytes, 100000)
            XCTAssertEqual(String(data: response, encoding: .utf8), "HTTP/1.1 200\r\nContent-Length: 100000\r\n\r\n")
            XCTAssertEqual(Data(count: 100000), try Data(contentsOf: fileDir.appendFile(fileName: "server_receive.txt").getURL()))
            
            let request2 = HTTPRequest(urlPath: "/server2.txt", method: .get, headers: ["Content-Length": "0"])
            let response2 = try await connection.downloadFile(request: request2, dirURL: fileDir, fileName: "server_receive2.txt")
            XCTAssertEqual(String(data: response2, encoding: .utf8), "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n\r\n")
            
            do {
                let request3 = HTTPRequest(urlPath: "/server-big.txt", method: .get, headers: ["Content-Length": "0"])
                _ = try await connection.downloadFile(request: request3, dirURL: fileDir, fileName: "server_receive3.txt") { bytesDownloaded in
                    connection.downloadFileCancel()
                }
                XCTFail("Expected downloadFile to throw, but it did not")
            } catch {
                XCTAssertEqual(error.localizedDescription, "Download was cancelled.")
            }
        } catch {
            XCTFail("Download file failed with error: \(error)")
        }
        
        try file.removeItem()
        try file2.removeItem()
        try fileDir.removeItem()
    }
    
    func testAddStateChangeObserver() async throws {
        do {
            let connection = try await HTTPConnection(host: "127.0.0.1", port: 8080, connectionTimeout: 10, keepAlive: true)
            let observer = MockObserver()
            connection.addStateChangeObserver(observer: observer)
            XCTAssertEqual(observer.lastObservedState, .connected)
        } catch {
            XCTFail("Add state change observer failed with error: \(error)")
        }
    }
}
