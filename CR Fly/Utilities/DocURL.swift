import Foundation

/// `DocURL` is a  class, that manages URLs for directories and files within the app's sandbox. This class provides methods to create, move, and query directories and files,vunifying the URL format and string path representation, providing methods to create, move, and query directories and files.
public class DocURL: Hashable {
    /// The path to the directory as a string.
    private let pathToDir: String
    /// The name of the file. If `nil`, it indicates a directory.
    private let fileName: String?
    
    /** Initializes a `DocURL` object with a given directory path and an optional file name.
    - Parameter dirURL: The directory path as a `URL`.
    - Parameter fileName: An optional file name as a `String`. If not provided, the `DocURL` represents a directory.
    */
    public init(dirURL: URL, fileName: String? = nil) {
        self.pathToDir = dirURL.standardizedFileURL.relativePath
        self.fileName = fileName
    }
    
    /** Initializes a `DocURL` object with a subdirectory path within the app's document directory and an optional file name.
    - Parameter  appDocDirPath: The subdirectory path within the app's document directory.
    - Parameter fileName: An optional file name as a `String`. If not provided, the `DocURL` represents a directory.
    */
    public init(appDocDirPath: String, fileName: String? = nil) {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let url = URL(fileURLWithPath: paths).appendingPathComponent(appDocDirPath)
        
        self.pathToDir = url.standardizedFileURL.relativePath
        self.fileName = fileName
    }
    
    /// Checks if the `DocURL` represents a directory.
    public func isDirectory() -> Bool {
        return self.fileName == nil
    }
    
    /// Gets the URL of the directory.
    public func getDirectoryURL() -> URL {
        return URL(filePath: self.pathToDir)
    }
    
    /// Gets the `String` representation of the directory's path.
    public func getDirectoryPath() -> String {
        return self.pathToDir
    }
    
    /// Gets the URL of the file or directory.
    public func getURL() -> URL {
        let path = self.fileName == nil ? self.pathToDir : self.pathToDir + "/" + self.fileName!
        return URL(filePath: path)
    }
    
    /// Gets the `String` representation of the items's path.
    public func getPath() -> String {
        return self.getURL().relativePath
    }
    
    /// Returns the file name associated with this `DocURL`.
    public func getFileName() -> String {
        return self.fileName ?? ""
    }
    
    public func getFileNameWithout(prefix: String) -> String {
        guard self.getFileName().hasPrefix(prefix) else {
            return self.getFileName()
        }
        return String(self.getFileName().dropFirst(prefix.count))
    }
    
    /// Retrieves the file extension of the file represented by this `DocURL`.
    public func getFileNameExtension() -> String {
        return self.fileName != nil ? self.getURL().pathExtension : ""
    }
    
    /// Retrieves the contents of the directory represented by this `DocURL`.
    public func getContentsOfDirectory(includingPropertiesForKeys: [URLResourceKey]? = nil, options: FileManager.DirectoryEnumerationOptions? = nil) throws -> [DocURL] {
        
        let content = options == nil ? try FileManager.default.contentsOfDirectory(at: self.getURL(), includingPropertiesForKeys: includingPropertiesForKeys) : try FileManager.default.contentsOfDirectory(at: self.getURL(), includingPropertiesForKeys: includingPropertiesForKeys, options: options!)
        
        var contentDocUrls: [DocURL] = []
        for item in content {
            contentDocUrls.append((DocURL(dirURL: item.deletingLastPathComponent(), fileName: item.lastPathComponent)))
        }
        
        return contentDocUrls
    }
    
    ///  Sets the attributes of the file or directory represented by this `DocURL`.
    public func setAttributesOfItem(attributes: [FileAttributeKey: Any]) throws {
        try FileManager.default.setAttributes(attributes, ofItemAtPath: self.getPath())
    }
    
    /// Retrieves the attributes of the file or directory represented by this `DocURL`.
    public func getAttributesOfItem() throws -> [FileAttributeKey: Any] {
        return try FileManager.default.attributesOfItem(atPath: self.getPath())
    }
    
    /// Creates a new `DocURL` by appending a directory name to the current path.
    public func appendDir(dirName: String) -> DocURL {
        return DocURL(dirURL: URL(fileURLWithPath: self.getDirectoryPath()).appendingPathComponent(dirName), fileName: self.fileName)
    }
    
    /// Creates a new `DocURL` by appending a file name to the current directory path or changing the current file name..
    public func appendFile(fileName: String) -> DocURL {
        return DocURL(dirURL: self.getDirectoryURL(), fileName: fileName)
    }
    
    /// Checks if a file or directory exists at the specified URL.
    public func existsItem() -> Bool {
        return FileManager.default.fileExists(atPath: self.getPath())
    }
    
    public func existsDirectory() -> Bool {
        return FileManager.default.fileExists(atPath: self.getDirectoryPath())
    }
    
    /** Creates a file or directory at the specified URL.
    - Parameter  withIntermediateDirectories: A Boolean value that indicates whether intermediate directories should be created.
    - Throws: An error if the file or directory could not be created.
    */
    public func createItem(withIntermediateDirectories: Bool = true) throws {
        if !self.existsDirectory() {
            try FileManager.default.createDirectory(at: self.getDirectoryURL(), withIntermediateDirectories: withIntermediateDirectories)
        }
        
        if self.fileName != nil, !self.existsItem() {
            FileManager.default.createFile(atPath: self.getURL().relativePath, contents: nil)
        }
    }
    
    /// Removes the file or directory represented by this `DocURL`.
    public func removeItem() throws {
        if self.existsItem() {
            try FileManager.default.removeItem(at: self.getURL())
        }
    }
    
    /** Moves the file or directory to a new location. If needed, create directory for `to`.
    - Parameter to: The destination `DocURL`.
    - Parameter withIntermediateDirectories: A Boolean value that indicates whether intermediate directories should be created.
    - Throws: An error if the file or directory could not be moved or if the source and destination types are incompatible.
    */
    public func moveItem(to: DocURL, withIntermediateDirectories: Bool = true) throws {
        if self == to { return }
        if self.isDirectory() == to.isDirectory() {
            if !FileManager.default.fileExists(atPath: to.getDirectoryURL().relativePath) {
                try FileManager.default.createDirectory(at: to.getDirectoryURL(), withIntermediateDirectories: withIntermediateDirectories)
            }
            try FileManager.default.moveItem(at: self.getURL(), to: to.getURL())
        } else {
            throw NSError(domain: "DocURL", code: 1, userInfo: [NSLocalizedDescriptionKey: "File could not be moved, because URLs are not compatible."])
        }
    }
    
    /** Copies the file or directory represented by this `DocURL` to a new location.
    - Parameter to: The destination `DocURL`.
    - Parameter withIntermediateDirectories: A Boolean value that indicates whether intermediate directories should be created if they do not exist. The default value is `true`.
    - Throws: An error if the item could not be copied or if the source and destination URLs are not compatible.
    */
    public func copyItem(to: DocURL, withIntermediateDirectories: Bool = true) throws {
        if self == to { return }
        if self.isDirectory() == to.isDirectory() {
            if !FileManager.default.fileExists(atPath: to.getDirectoryURL().relativePath) {
                try FileManager.default.createDirectory(at: to.getDirectoryURL(), withIntermediateDirectories: withIntermediateDirectories)
            }
            try FileManager.default.copyItem(at: self.getURL(), to: to.getURL())
        } else {
            throw NSError(domain: "DocURL", code: 1, userInfo: [NSLocalizedDescriptionKey: "File could not be moved, because URLs are not compatible."])
        }
    }
    
    public static func == (lhs: DocURL, rhs: DocURL) -> Bool {
        return lhs.getPath() == rhs.getPath()
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(self.getPath())
    }
}
