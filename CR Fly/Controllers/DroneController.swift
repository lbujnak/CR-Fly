import Foundation

/// `DroneController` orchestrates the management and interaction of drone-related data and operations within an application. It extends `CommandQueueController` to leverage command queuing mechanisms, ensuring operations are performed sequentially and safely in a multi-threaded environment.
public protocol DroneController: CommandQueueController {
    /// Provides read-only access to the data model that encapsulates essential data related to a drone, including its connection status and necessary information for operation.
    var droneData: DroneData { get }
    
    /// Ensures that the `calculateDownloadSpeed()` method is executed only once at a time, preventing multiple parallel executions of this function.
    var speedCalcIdentifier: String { get set }
    
    /// Resumes a previously paused download process, continuing data retrieval from the last checkpoint. This function is used to restart the download without losing progress, optimizing bandwidth and user time.
    func enterFromBackground()
    
    /// Prepares the application for transition to the background by saving state, pausing ongoing tasks, or securing sensitive information.
    func leaveToBackground()
    
    /// Manages various actions related to media downloads within the application. This method unifies the control of download processes, allowing the user to resume, pause, or completely stop media downloads. This design simplifies the interface for handling download actions, making it easier to manage network resources and user interactions with ongoing downloads.
    func manageDownload(action: MediaTransferAction)
    
    /// Handler used to respond canceled uploads, listing affected files.
    func uploadCanceledFor(fileNames: Set<String>)
    
    /// Opens the First Person View (FPV) User Interface for the drone, allowing real-time video streaming from the drone's camera to the application's user interface. This method is typically called to enable users to view live footage directly from the drone, essential for navigating or monitoring remote areas.
    func openFPVView()
}

public extension DroneController {
    /// Initiates the process of dynamically updating the download speed. This method sets the run identifier and begins the speed calculation process.
    func startUpdatingDownloadSpeed() {
        let runIdentifier = UUID().uuidString
        self.speedCalcIdentifier = runIdentifier
        self.calculateDownloadSpeed(runIdentifier: runIdentifier)
    }
    
    /// Dynamically updates the download speed based on the amount of data downloaded since the last calculation. This method checks if the download is active and not paused, calculates the new speed in Bps, and schedules itself to run again in 500 milliseconds. This ensures continuous monitoring and updating of the download speed during the media download process.
    private func calculateDownloadSpeed(runIdentifier: String) {
        if(self.speedCalcIdentifier == runIdentifier) {
            if self.droneData.mediaDownloadState != nil, !self.droneData.mediaDownloadState!.transferPaused {
                let downloaded = self.droneData.mediaDownloadState!.transferedBytes
                
                if self.droneData.mediaDownloadState!.speedCalcLastBytes > downloaded {
                    self.droneData.mediaDownloadState!.speedCalcLastBytes = downloaded
                }
                
                let realByteCnt: UInt! = downloaded - self.droneData.mediaDownloadState!.speedCalcLastBytes
                let newSpeed = Double(realByteCnt) * 2
                
                self.droneData.mediaDownloadState!.transferSpeed = newSpeed
                self.droneData.mediaDownloadState!.speedCalcLastBytes = downloaded
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                    self.calculateDownloadSpeed(runIdentifier: runIdentifier)
                }
            }
        }
    }
}
