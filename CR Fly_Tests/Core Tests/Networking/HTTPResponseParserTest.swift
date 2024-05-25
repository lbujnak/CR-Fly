import Foundation
import XCTest
@testable import CR_Fly

final class HTTPResponseParserTests: XCTestCase {
    func testInitializationWithValidData() {
        let httpResponseString = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{\"key\": \"value\"}"
        let data = httpResponseString.data(using: .utf8)!
        let parser = HTTPResponseParser(data: data)
        
        XCTAssertNotNil(parser)
        XCTAssertEqual(parser?.statusCode, 200)
        XCTAssertEqual(parser?.headers["Content-Type"], "application/json")
        XCTAssertEqual(parser?.body, "{\"key\": \"value\"}".data(using: .utf8))
    }
    
    func testInitializationWithInvalidData() {
        let invalidResponseString = "INVALID RESPONSE"
        let data = invalidResponseString.data(using: .utf8)!
        let parser = HTTPResponseParser(data: data)
        
        XCTAssertNil(parser)
    }
    
    func testInitializationWithPartialHeaders() {
        let partialHeaderResponseString = "HTTP/1.1 200 OK\r\nContent-Type\r\n\r\n{\"key\": \"value\"}"
        let data = partialHeaderResponseString.data(using: .utf8)!
        let parser = HTTPResponseParser(data: data)
        
        XCTAssertNotNil(parser)
        XCTAssertEqual(parser?.statusCode, 200)
        XCTAssertNil(parser?.headers["Content-Type"])
        XCTAssertEqual(parser?.body, "{\"key\": \"value\"}".data(using: .utf8))
    }
    
    func testBodyTo1DJSON() {
        let httpResponseString = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n[\"value1\", \"value2\"]"
        let data = httpResponseString.data(using: .utf8)!
        let parser = HTTPResponseParser(data: data)
        
        XCTAssertNotNil(parser)
        let jsonArray = parser?.bodyTo1DJSON()
        XCTAssertEqual(jsonArray, ["value1", "value2"])
    }
    
    func testBodyTo2DJSON() {
        let httpResponseString = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{\"key\": \"value\"}"
        let data = httpResponseString.data(using: .utf8)!
        let parser = HTTPResponseParser(data: data)
        
        XCTAssertNotNil(parser)
        let jsonDict = parser?.bodyTo2DJSON()
        XCTAssertEqual(jsonDict?["key"] as? String, "value")
    }
    
    func testBodyTo3DJSON() {
        let httpResponseString = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n[{\"key\": \"value1\"}, {\"key\": \"value2\"}]"
        let data = httpResponseString.data(using: .utf8)!
        let parser = HTTPResponseParser(data: data)
        
        XCTAssertNotNil(parser)
        let jsonArrayOfDicts = parser?.bodyTo3DJSON()
        XCTAssertEqual(jsonArrayOfDicts?.count, 2)
        XCTAssertEqual(jsonArrayOfDicts?[0]["key"] as? String, "value1")
        XCTAssertEqual(jsonArrayOfDicts?[1]["key"] as? String, "value2")
    }
    
    func testStaticParseTo2DJSON() {
        let jsonString = "{\"key\": \"value\"}"
        let data = jsonString.data(using: .utf8)
        let jsonDict = HTTPResponseParser.parseTo2DJSON(data: data)
        
        XCTAssertNotNil(jsonDict)
        XCTAssertEqual(jsonDict?["key"] as? String, "value")
    }
    
    func testStaticParseTo3DJSON() {
        let jsonString = "[{\"key\": \"value1\"}, {\"key\": \"value2\"}]"
        let data = jsonString.data(using: .utf8)
        let jsonArrayOfDicts = HTTPResponseParser.parseTo3DJSON(data: data)
        
        XCTAssertNotNil(jsonArrayOfDicts)
        XCTAssertEqual(jsonArrayOfDicts?.count, 2)
        XCTAssertEqual(jsonArrayOfDicts?[0]["key"] as? String, "value1")
        XCTAssertEqual(jsonArrayOfDicts?[1]["key"] as? String, "value2")
    }
    
    func testInitializationWithEmptyData() {
        let emptyData = Data()
        let parser = HTTPResponseParser(data: emptyData)
        
        XCTAssertNil(parser)
    }
}
