import Foundation

/// `MediaTransferAction` is an enumeration that defines the set of actions applicable to media transfer processes within an application. This enum is designed to manage state transitions for media transfer operations such as downloads or uploads, providing a clear interface for stopping, resuming and pausing these operations.
public enum MediaTransferAction {
    /// Resumes a previously paused transfer process, continuing data retrieval from the last checkpoint.
    case resumeTransfer
    
    /// Temporarily halts the ongoing download process, allowing it to be resumed later from the same point. 
    case pauseTransfer
    
    /// Completely terminates the ongoing transfer and clears associated resources. This action cannot be undone, and any progress made in the transfer will be lost, requiring a restart from the beginning if needed.
    case stopTransfer
}
