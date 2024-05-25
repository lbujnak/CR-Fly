import DJISDK
import Foundation

/**
 `MediaDownloadState` extends `MediaTransferState` to specifically manage the state of media downloads from DJI drones. This struct encapsulates all pertinent information necessary for effectively managing download operations and updating the user interface to reflect the progress and status of these downloads.
 
 - This struct is primarily used to monitor and control media downloads from DJI drones, allowing for responsive UI updates and efficient management of downloading resources. It aids in providing a user-friendly download interface by exposing detailed progress metrics and control mechanisms such as pause and resume.
 
 - Note: `MediaDownloadState` is critical in applications where real-time download management and status display are required, particularly in environments where network conditions and external controls may frequently change the state of media transfers.
 */
public struct MediaDownloadState: MediaTransferState {
    // MARK: Management Properties
    
    /// A set of `DJIMediaFile` objects representing the queue of files currently being downloaded.
    public var downloadSet: Set<DJIMediaFile> = []
    
    /// A set of `DJIMediaFile` objects that are temporarily downloaded for ongoing upload.
    public var tempDownload: Set<DJIMediaFile> = []
    
    /// An optional `DJIMediaFile` that points to the file currently being downloaded, if any.
    public var currentDownloadFile: DJIMediaFile? = nil
    
    /// An unsigned integer representing the byte offset in the `currentDownloadFile` describing count of bytes downloaded.
    public var currentFileOffset: UInt = 0
    
    // MARK: Management + UI Dependent Presentation Properties
    
    /// A boolean indicating whether the current transfer process is paused. This is useful for temporarily halting the transfer without cancelling it entirely.
    public var transferPaused: Bool = true
    
    /// A boolean indicating whether the transfer has been forcefully paused, typically due to an external condition or requirement that prevents continuation.
    public var transferForcePaused: Bool = true
    
    /// An integer counting the total number of media files expected to be downloaded in the current session.
    public var totalMedia: Int = 0
    
    /// An unsigned integer representing the total size, in bytes, of all media files being downloaded.
    public var totalBytes: UInt = 0
    
    /// An unsigned integer storing the byte position used in the last calculation of download speed, helping to measure download speed accurately.
    public var speedCalcLastBytes: UInt = 0
    
    /// A float indicating the current speed of the download in megabytes per second.
    public var transferSpeed: Double = 0
    
    /// An integer counting the number of media files that have been completely downloaded.
    public var transferedMedia: Int = 0
    
    /// An unsigned integer showing the total number of bytes downloaded so far.
    public var transferedBytes: UInt = 0
}
