import Foundation

/**
 `MediaUploadState` extends `MediaTransferState` to specifically manage the state of media uploads in an application. This struct encapsulates all pertinent information necessary for effectively managing upload operations and updating the user interface to reflect the progress and status of these uploads.
 
 - This struct is primarily used to monitor and control media uploads, allowing for responsive UI updates and efficient management of uploading resources. It aids in providing a user-friendly upload interface by exposing detailed progress metrics and control mechanisms such as pause and resume.
 
 - Note: `MediaUploadState` is crucial in applications where real-time upload management and status display are required, especially in environments where network conditions and external controls may frequently affect the state of media transfers.
 */
public struct MediaUploadState: MediaTransferState {
    /// A struct to represent the data of a file being downloaded.
    public struct DownloadFileData: Hashable {
        /// The name of the file being downloaded.
        let fileName: String
        
        /// The size of the file being downloaded, in bytes.
        let fileSize: UInt
    }
    
    // MARK: Management Properties
    
    /// A set of `DocURL` objects representing the queue of files currently being uploaded. This set helps manage and track files during the upload process.
    public var uploadSet: Set<DocURL> = []
    
    /// A set of `DownloadFileData` representing files that need to be downloaded before they can be uploaded.
    public var waitDownload: Set<DownloadFileData> = []
    
    /// An unsigned integer representing the byte offset in the first file of `uploadSet`describing count of bytes uploaded.
    public var currentFileOffset: UInt = 0
    
    // MARK: Management + UI Dependent Presentation Properties
    
    /// A boolean indicating whether the current transfer process is paused. This is useful for temporarily halting the transfer without cancelling it entirely.
    public var transferPaused: Bool = true
    
    /// A boolean indicating whether the transfer has been forcefully paused, typically due to an external condition or requirement that prevents continuation.
    public var transferForcePaused: Bool = true
    
    /// An integer representing the total number of media files expected to be uploaded in the current session.
    public var totalMedia: Int = 0
    
    /// An unsigned integer showing the total size, in bytes, of all media files being uploaded.
    public var totalBytes: UInt = 0
    
    /// An unsigned integer used in the last calculation of upload speed to measure progress and performance.
    public var speedCalcLastBytes: UInt = 0
    
    /// A float indicating the current speed of the upload in megabytes per second.
    public var transferSpeed: Double = 0
    
    /// An integer tallying the number of media files that have been successfully uploaded.
    public var transferedMedia: Int = 0
    
    /// An unsigned integer representing the total number of bytes successfully uploaded so far.
    public var transferedBytes: UInt = 0
}
