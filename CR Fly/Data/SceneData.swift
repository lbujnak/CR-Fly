import SwiftUI

/// `SceneData` is an observable data model class that tracks and communicates changes in the reconstruction software within an application. It monitors and broadcasts changes in scene connectivity, project data, media upload processes, and UI interaction permissions, supporting a responsive and user-friendly interface for scene management tasks.
public class SceneData: ObservableObject {
    /// A boolean flag indicating whether the application has an active connection to the scene or 3D environment, crucial for enabling or disabling scene-related operations.
    @Published var sceneConnected = false
    
    /// A boolean flag that becomes true if the connection to the scene was established but then lost, aiding in troubleshooting and user notifications about connection stability.
    @Published var sceneConnLost = false
    
    /// A boolean that when set to true, disables user interactions with the UI, typically used during critical operations that require user attention or during long-running processes to prevent unintended actions.
    @Published var disableUIInteraction: Bool = false
    
    /// An instance of `SceneProjectInfo` storing details about the currently opened project within the scene, such as the project's status, metadata, and other relevant attributes.
    @Published var openedProject = SceneProjectInfo()
    
    /// A dictionary mapping project names to their sort order, used for managing and displaying a list of available projects in the UI.
    @Published var projectList: [String: Int] = ["<none>": Int.max]
    
    /// A dictionary storing the unique identifiers associated with each project, facilitating project management tasks and data consistency.
    @Published var projectGUIDs: [String: String] = [:]
    
    /// An optional `MediaUploadState` that captures the current state of media being uploaded to the scene, including progress and status information, useful for tracking upload operations and displaying progress in the UI.
    @Published var mediaUploadState: MediaUploadState? = nil
    
    /// An optional `DocURL` pointing to the location where exported 3D models are stored, providing quick access to exported data for user download or external processing.
    @Published var exportedModelsURL: DocURL? = nil
}
