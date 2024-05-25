import XCTest
@testable import CR_Fly

final class DocURLTests: XCTestCase {
    
    var baseUrl: URL!
    var baseDocUrl: DocURL!
    
    override func setUp() {
        super.setUp()
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        baseUrl = URL(fileURLWithPath: paths).appendingPathComponent("Test DocURL")
        baseDocUrl = DocURL(dirURL: baseUrl)
    }
    
    override func tearDown() {
        baseUrl = nil
        super.tearDown()
    }
    
    func testFormatFromDirURL() {
        XCTAssertEqual(baseDocUrl.getPath(), baseUrl.relativePath)
        XCTAssertEqual(baseDocUrl.getDirectoryPath(), baseUrl.relativePath)
        XCTAssertEqual(DocURL(dirURL: baseUrl).getURL(), baseDocUrl.getURL())
        XCTAssertEqual(DocURL(dirURL: baseUrl.absoluteURL).getURL(), baseDocUrl.getURL())
        XCTAssertEqual(DocURL(dirURL: baseUrl.standardizedFileURL).getURL(), baseDocUrl.getURL())
        XCTAssertEqual(DocURL(dirURL: baseUrl.standardizedFileURL).getURL(), baseDocUrl.getURL())
        XCTAssertEqual(DocURL(dirURL: URL(string: baseUrl.relativePath)!).getURL(), baseDocUrl.getURL())
        XCTAssertEqual(DocURL(dirURL: URL(string: baseUrl.relativeString)!).getURL(), baseDocUrl.getURL())
        XCTAssertEqual(DocURL(dirURL: URL(string: baseUrl.absoluteString)!).getURL(), baseDocUrl.getURL())
        XCTAssertEqual(DocURL(dirURL: URL(string: baseUrl.path)!).getURL(), baseDocUrl.getURL())
    }
    
    func testFormatFromAppDocDirPath() {
        XCTAssertEqual(baseDocUrl.getPath(), baseUrl.relativePath)
        XCTAssertEqual(baseDocUrl.getPath(), DocURL(appDocDirPath: "/Test DocURL").getPath())
        XCTAssertEqual(baseDocUrl.getPath(), DocURL(appDocDirPath: "//Test DocURL").getPath())
    }
    
    func testCreation() throws {
        XCTAssertFalse(FileManager.default.fileExists(atPath: baseDocUrl.getPath()))
        XCTAssertFalse(baseDocUrl.existsItem())
        try baseDocUrl.createItem(withIntermediateDirectories: true)
        XCTAssertTrue(FileManager.default.fileExists(atPath: baseDocUrl.getPath()))
        XCTAssertTrue(baseDocUrl.existsItem())
        
        let dcUrl2 = DocURL(appDocDirPath: "Test DocURL/Dummy")
        XCTAssertFalse(FileManager.default.fileExists(atPath: dcUrl2.getPath()))
        XCTAssertFalse(dcUrl2.existsItem())
        try dcUrl2.createItem(withIntermediateDirectories: true)
        XCTAssertTrue(FileManager.default.fileExists(atPath: dcUrl2.getPath()))
        XCTAssertTrue(dcUrl2.existsItem())
        
        let dcUrl3 = DocURL(appDocDirPath: "Test DocURL/Dummy/Dummy2", fileName: "File.txt")
        XCTAssertFalse(FileManager.default.fileExists(atPath: dcUrl3.getPath()))
        XCTAssertFalse(dcUrl3.existsItem())
        try dcUrl3.createItem(withIntermediateDirectories: true)
        XCTAssertTrue(FileManager.default.fileExists(atPath: dcUrl3.getPath()))
        XCTAssertTrue(dcUrl3.existsItem())
        
        try dcUrl3.removeItem()
        try dcUrl2.removeItem()
        try baseDocUrl.removeItem()
        
        XCTAssertFalse(dcUrl3.existsItem())
        XCTAssertFalse(dcUrl2.existsItem())
        XCTAssertFalse(baseDocUrl.existsItem())
    }
    
    func testMoveCopy() throws {
        let dcUrl2 = DocURL(appDocDirPath: "Test DocURL/Dummy/Dummy2")
        let dcUrl3 = DocURL(appDocDirPath: "Test DocURL/Dummy/Dummy2", fileName: "File.txt")
        
        XCTAssertFalse(baseDocUrl.existsItem())
        XCTAssertFalse(dcUrl2.existsItem())
        
        XCTAssertFalse(dcUrl3.existsItem())
        try dcUrl3.createItem(withIntermediateDirectories: true)
        XCTAssertTrue(dcUrl3.existsItem())
        
        try dcUrl3.moveItem(to: dcUrl3, withIntermediateDirectories: true)
        XCTAssertTrue(dcUrl3.existsItem())
        
        let dcUrl4 = DocURL(appDocDirPath: "Test DocURL/Dummy/Dummy2/Dummy3", fileName: "File.txt")
        try dcUrl3.moveItem(to: dcUrl4, withIntermediateDirectories: true)
        XCTAssertTrue(dcUrl4.existsItem())
        XCTAssertFalse(dcUrl3.existsItem())
        
        try dcUrl4.copyItem(to: dcUrl3)
        XCTAssertTrue(dcUrl4.existsItem())
        XCTAssertTrue(dcUrl3.existsItem())
        
        let dcUrl5 = DocURL(appDocDirPath: "Test DocURL/Move/And/Copy", fileName: "File.blabla")
        try dcUrl4.copyItem(to: dcUrl5)
        XCTAssertTrue(dcUrl5.existsItem())
        XCTAssertTrue(dcUrl3.existsItem())
        
        try dcUrl3.removeItem()
        try dcUrl4.removeItem()
        try dcUrl5.removeItem()
        XCTAssertFalse(dcUrl3.existsItem())
        XCTAssertFalse(dcUrl4.existsItem())
        XCTAssertFalse(dcUrl5.existsItem())
        
        do {
            try dcUrl2.moveItem(to: dcUrl3, withIntermediateDirectories: true)
        } catch {
            XCTAssertNotNil(error)
        }
        
        try baseDocUrl.removeItem()
        XCTAssertFalse(baseDocUrl.existsItem())
    }
    
    func testAppendToPath() throws {
        let dcUrl2 = baseDocUrl.appendDir(dirName: "Dummy")
        let dcUrl3 = baseDocUrl.appendDir(dirName: "/Dummy")
        
        XCTAssertEqual(dcUrl2.getPath(), baseDocUrl.getURL().appendingPathComponent("Dummy").relativePath)
        XCTAssertEqual(dcUrl3.getPath(), baseDocUrl.getURL().appendingPathComponent("Dummy").relativePath)
        
        let dcUrl4 = dcUrl2.appendFile(fileName: "test.txt")
        let dcUrl5 = dcUrl4.appendFile(fileName: "test2.txt")
        let dcUrl6 = dcUrl4.appendFile(fileName: "_tmp.test2.txt")
        let dcUrl7 = dcUrl4.appendFile(fileName: "_tmp123.test2.txt")
        
        XCTAssertEqual(dcUrl6.getFileNameWithout(prefix: "_tmp."), "test2.txt")
        XCTAssertEqual(dcUrl7.getFileNameWithout(prefix: "_tmp12"), "3.test2.txt")
        
        XCTAssertEqual(dcUrl4.getPath(), baseDocUrl.getURL().appendingPathComponent("Dummy").appendingPathComponent("test.txt").relativePath)
        XCTAssertEqual(dcUrl5.getPath(), baseDocUrl.getURL().appendingPathComponent("Dummy").appendingPathComponent("test2.txt").relativePath)
        XCTAssertEqual(dcUrl4.getFileName(), "test.txt")
        XCTAssertEqual(dcUrl4.getFileNameExtension(), "txt")
        XCTAssertEqual(dcUrl5.getFileName(), "test2.txt")
        XCTAssertEqual(dcUrl5.getFileNameExtension(), "txt")
    }
    
    func testGetSet() throws{
        do {
            _ = try baseDocUrl.getAttributesOfItem()
        } catch { XCTAssertNotNil(error)}
        
        do {
            _ = try baseDocUrl.getContentsOfDirectory()
        } catch { XCTAssertNotNil(error)}
        
        let file = baseDocUrl.appendFile(fileName: "text.txt")
        
        do {
            _ = try file.getAttributesOfItem()
        } catch { XCTAssertNotNil(error)}
        
        try file.createItem()
        do {
            _ = try file.getContentsOfDirectory()
        } catch { XCTAssertNotNil(error)}
        
        let attributes = try baseDocUrl.getAttributesOfItem()
        XCTAssertNotNil(attributes)
        
        try baseDocUrl.setAttributesOfItem(attributes: attributes)
        
        XCTAssertNotNil(try baseDocUrl.getContentsOfDirectory())
        XCTAssertNotNil(try file.getAttributesOfItem())
        
        try file.removeItem()
        try baseDocUrl.removeItem()
        XCTAssertFalse(baseDocUrl.existsItem())
        XCTAssertFalse(file.existsItem())
    }
}
