import Foundation

/// `MediaTransferState` is a protocol designed to standardize the user interface presentation data for media transfer processes such as uploads or downloads within an application. By defining a common set of properties, this protocol ensures consistency and facilitates the reusability of UI components that display media transfer progress and statistics.
public protocol MediaTransferState {
    /// A boolean indicating whether the current transfer process is paused. This is useful for temporarily halting the transfer without cancelling it entirely.
    var transferPaused: Bool { get set }
    
    /// A boolean indicating whether the transfer has been forcefully paused, typically due to an external condition or requirement that prevents continuation.
    var transferForcePaused: Bool { get set }
    
    /// An integer representing the total number of media files expected to be uploaded in the current session.
    var totalMedia: Int { get set }
    
    /// An unsigned integer showing the total size, in bytes, of all media files being uploaded.
    var totalBytes: UInt { get set }
    
    /// An unsigned integer used in the last calculation of upload speed to measure progress and performance.
    var speedCalcLastBytes: UInt { get set }
    
    /// A float indicating the current speed of the upload in megabytes per second.
    var transferSpeed: Double { get set }
    
    /// An integer tallying the number of media files that have been successfully uploaded.
    var transferedMedia: Int { get set }
    
    /// An unsigned integer representing the total number of bytes successfully uploaded so far.
    var transferedBytes: UInt { get set }
}
