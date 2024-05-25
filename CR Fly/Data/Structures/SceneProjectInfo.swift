import Foundation

/// `SceneProjectInfo` is a protocol that defines the essential properties and state indicators for a project in a scene management system. It is used to track and manage the current status, metadata, and operational tasks related to a specific project.
public struct SceneProjectInfo {
    /// `ProjectUpdateState` is an enumeration that defines the different states of updating or processing a scene project. Each state represents a specific phase in the data fetching or processing workflow, providing clear, human-readable descriptions of each stage.
    public enum ProjectUpdateState {
        /// Indicates that the system is currently fetching a list of project inputs.
        case fetchProjectInputList
        
        /// Indicates that the system is currently fetching a list of project outputs.
        case fetchProjectOutputList
        
        /// Represents the state where the system is fetching data from template exports.
        case fetchDataFromExports
        
        /// Indicates that the system is currently downloading model from reconstruction software.
        case downloadLoadModel(SceneModelData.SceneModelType)
        
        /// Adds description to each case.
        var description: String {
            switch self {
            case .fetchProjectInputList:
                "Fetching project input list..."
            case .fetchProjectOutputList:
                "Fetching project output list..."
            case .fetchDataFromExports:
                "Fetching data from template exports..."
            case let .downloadLoadModel(model):
                "Downloading and loading \(model.rawValue)..."
            }
        }
    }
    
    /// `TaskStatus` is a struct that defines the status and metadata for a specific task within a scene. It is designed to track the progress and status of various tasks such as data processing, scene rendering, or other long-running operations associated with scene management.
    public struct TaskStatus {
        /// A string representing the name of the task. This name is used to identify the task in logs or UI components.
        public let taskName: String
        
        /// A string providing a brief description of what the task entails. This is helpful for displaying in user interfaces or debugging outputs.
        public let taskDescription: String
        
        /// An optional integer denoting the start time of the task, typically measured in seconds or ticks since a reference time. `nil` indicates the task has not yet begun.
        public var taskTimeStart: Int?
        
        /// An optional integer  indicating the end time of the task, similar in format to `taskTimeStart`. `nil` signifies that the task is ongoing or the end time has not yet been recorded.
        public var taskTimeEnd: Int?
        
        /// An optional string representing the current state of the task, such as "scheduled", "started", "finished", or "failed". This can be used to dynamically update the task's status in a monitoring system or user interface.
        public var taskState: String?
    }
    
    // MARK: Neccessary for UI
    
    /// A boolean value indicating whether the project's data is fully loaded into the application. This property is crucial for ensuring that operations on the project do not commence until all necessary data has been properly initialized.
    public var loaded: Bool = false
    
    /// A boolean value that indicates whether the project is ready to receive data from application. This is typically used to control UI elements like upload buttons or to trigger automated upload processes.
    public var readyToUpload: Bool = false
    
    /// A string value representing the name of the project. This is used for display purposes in the user interface and for identification in logs and data storage.
    public var name: String = "<none>"
    
    /// An optional string that provides a unique identifier for the session under which the project is loaded. This can be used to track sessions in analytics or manage data syncing across different sessions.
    public var sessionID: String?
    
    /// An optional `SceneProjectUpdateState` value that describes the current update state of the project. This is used to provide user feedback and control flow within the application based on the stage of data processing or retrieval.
    public var projectUpdateState: ProjectUpdateState?
    
    /// A dictionary mapping string keys to tuples, where each tuple contains an optional `Command` object, which will be pushed to command queue when a task described by `SceneTaskStatus` finished it's execution.
    public var waitingOnTask: [String: (Command?, TaskStatus)] = [:]
    
    /// An optional `SceneModelData.SceneModelType` indicating that app recently executed `ExportSelectModel` command which succeded and download of this model is required.
    public var exportModelReady: SceneModelData.SceneModelType?
    
    /// A set of strings representing the list of files associated with the project, used for tracking and management.
    public var fileList: Set<String> = []
    
    // MARK: Data from export of Project Info Template
    
    /// An integer that represents number of images that are used in reconstruction.
    public var imageCnt: Int?
    
    /// An integer of components found in reconstruction.
    public var componentCnt: Int?
    
    /// An integer of valid points in pointcloud that have been detected in reconstruction (tie points).
    public var pointCnt: Int?
    
    /// An integer of valid cameras that have been found during reconstruction.
    public var cameraCnt: Int?
    
    /// An integer of measurements that have been found during reconstruction.
    public var measurementCnt: Int?
    
    // MARK: Data obtained by GetProjectStatus
    
    /// An optional boolean indicating if the project was restarted, often used to trigger reinitialization or special logging.
    public var restarted: Bool?
    
    /// An optional double representing the progress of the current task, expressed as a percentage, facilitating real-time monitoring.
    public var progress: Double?
    
    /// An optional double indicating the total time the last task has been running, expressed in seconds.
    public var timeTotal: Double?
    
    /// An optional double providing an estimation of the time required to complete the current task, expressed in seconds.
    public var timeEstimation: Double?
    
    /// An optional integer capturing error codes from task executions, useful for error handling and debugging.
    public var errorCode: Int?
    
    /// An optional integer tracking the number of changes made in the project, used for version control or change management.
    public var changeCounter: Int?
    
    /// An optional integer representing the last change counter value handled by the application, ensuring synchronization between client and server.
    public var savedChangeCounter: Int?
    
    /// An optional integer identifying the process ID of the current task, useful for tracking and management of concurrent tasks.
    public var processID: Int?
}
