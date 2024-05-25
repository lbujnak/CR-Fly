import Foundation

/// `DroneData` is an observable data model class that tracks and communicates changes in the drone's state within an application. It supports functionality for drone connectivity status, operational modes, and media download management, facilitating a reactive and synchronized UI for drone-related operations.
public class DroneData: ObservableObject {
    /// A boolean that indicates whether the drone is currently connected to the application. This property is crucial for enabling or disabling functionalities that require active drone connectivity.
    @Published var deviceConnected = false
    
    /// A boolean that specifies whether the drone is in playback mode, which typically means reviewing or processing recorded media directly from the drone.
    @Published var playbackMode: Bool = false
    
    /// An optional `MediaDownloadState` that holds information about the current status of media being downloaded from the drone, including progress, errors, and completion state. This allows detailed tracking and management of media transfers from the drone to the application.
    @Published var mediaDownloadState: MediaDownloadState? = nil
}
