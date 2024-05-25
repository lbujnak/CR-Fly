import DJISDK
import SwiftUI

/**
 `RCNodeController` extends `CommandQueueController` and implements `SceneController` and `HTTPConnectionStateObserver` protocols, providing comprehensive management functionalities for handling operations related to RealityCapture Node (RCNode). This includes project management, HTTP connection handling, and command execution for interacting with an RCNode.
 
 - Responsibilities:
     - Managing project operations such as opening, closing, creating, and deleting projects on an RCNode.
     - Handling the state of HTTP connections to ensure robust communication with the RCNode.
     - Observing and responding to changes in HTTP connection states.
     - Executing and managing a queue of commands that interact with the RCNode.
     - Providing UI-related functionalities to interact with the scene and projects efficiently.
 
 - Usage:
     - This class is used in applications that require direct interaction with RCNode, facilitating operations like project management, data retrieval, and status monitoring.
     - It acts as the central controller for all RCNode-related activities within the application, ensuring that the operations are performed efficiently and state changes are handled promptly.
 
 The controller maintains an active connection with the RCNode, manages the execution of commands, and updates the user interface based on the operations' outcomes and changes in the connection state.
 */
public class RCNodeController: CommandQueueController, SceneController, HTTPConnectionStateObserver {
    /// Reference to the `ViewController` responsible for managing navigation, presentation of different views within the application and displaying errors.
    private let viewController: ViewController
    
    /// Provides read-only access to the data pertinent to the current scene in the reconstruction software.
    public let sceneData = SceneData()
    
    /// Provides read-only access to the data models associated with the scene, such as `PointCloud` and various 3D models, enabling operations on these models.
    public let sceneModelData = SceneModelData()
    
    /// Ensures that the `calculateUploadSpeed()` method is executed only once at a time, preventing multiple parallel executions of this function.
    public var speedCalcIdentifier : String = ""
    
    /// An optional `HTTPConnection` that represents current HTTP connection with the RCNode, if available.
    public var nodeConnection: HTTPConnection? = nil
    
    /// A string that represents the authentication token used for securing connections and requests to the RCNode.
    public var nodeAuthToken = ""
    
    /// A string that represents the current status of the RCNode as last updated from the RCNode itself.
    public var nodeStatus: String? = nil
    
    /// A string that represents the number of available sessions that can be initiated with the RCNode.
    public var availableSessions: Int = 0
    
    /// A boolean flag indicating if the application is currently in the background.
    private var appInBackground = false
    
    /// A `DispatchTimeInterval` used for automatically updating the node state when the app is active.
    private var autoUpdateTimeout: DispatchTimeInterval = .seconds(1)
    
    /// A `DispatchTimeInterval` that represents the interval for updating the node state when the app is in the background.
    private var bckgUpdateTimeout: DispatchTimeInterval = .seconds(5)
    
    /// An integer tha trepresents the unique identifier used for node auto updates.
    private var nodeAutoUpdateIdentifier = 0
    
    /**
     Initializes a new instance of `RCNodeController` with a specified view controller.
     - Parameter viewController: The main view controller responsible for UI interactions.
     */
    public init(viewController: ViewController) {
        self.viewController = viewController
        super.init(commandRetries: 3, commandRetryTimeout: 1000, viewController: viewController)
        
        self.sceneData.exportedModelsURL = DocURL(appDocDirPath: "Exported Models")
        if !FileManager.default.fileExists(atPath: self.sceneData.exportedModelsURL!.getPath()) {
            do {
                try FileManager.default.createDirectory(at: self.sceneData.exportedModelsURL!.getURL(), withIntermediateDirectories: true)
            } catch {
                self.sceneData.exportedModelsURL = nil
                print("Error Opening Export Models Directory: \(error.localizedDescription)")
                return
            }
        }
    }
    
    // MARK: SceneController Methods
    
    /// Executes necessary actions when the application transitions from background to foreground, such as reinitializing resources or updating the UI.
    public func enterFromBackground() {
        self.appInBackground = false
        
        if self.sceneData.openedProject.loaded {
            self.loadSavedModels()
        }
    }
    
    /// Prepares the application for transition to the background by saving state, pausing ongoing tasks, or securing sensitive information.
    public func leaveToBackground() {
        self.appInBackground = true
        
        self.nodeConnection?.terminateConnection()
        if self.sceneData.openedProject.loaded {
            self.pushCommand(command: GetProjectSave(projectName: self.sceneData.openedProject.name))
        }
    }
    
    /// Terminates all active connections and stops all ongoing communication with the reconstruction software.
    public func disconnectScene() {
        self.nodeConnection?.terminateConnection()
    }
    
    /// Manages various actions related to projects within the reconstruction software. This method consolidates multiple project-related actions into a single function call. It allows for refreshing, changing, saving, closing, and deleting projects based on the specified action.
    public func manageProject(action: SceneProjectAction) {
        switch action {
        case .refreshProject:
            self.pushCommand(command: GetNodeProjects())
            self.pushCommand(command: GetProjectStatus())
        case let .changeProjectTo(newProjectName):
            let projectData = self.sceneData.projectGUIDs[newProjectName]
            if projectData == nil {
                self.pushCommand(command: GetProjectCreate(projectName: newProjectName))
            } else {
                self.pushCommand(command: GetProjectOpen(projectID: projectData!))
            }
            self.pushCommand(command: GetProjectList(folder: .output))
        case .saveProject:
            self.pushCommand(command: GetProjectSave(projectName: self.sceneData.openedProject.name))
        case .closeProject:
            self.pushCommand(command: GetProjectSave(projectName: self.sceneData.openedProject.name))
            self.pushCommand(command: GetProjectClose())
        case .deleteProject:
            let projectData = self.sceneData.projectGUIDs[self.sceneData.openedProject.name]
            if projectData == nil {
                self.viewController.showSimpleAlert(title: "Error Deleting RCNode Project", msg: Text("The selected project for deletion is not in the list of projects."))
            } else {
                self.pushCommand(command: GetProjectDelete(projectID: projectData!))
            }
        }
    }
    
    /// Generates a custom view providing a structured presentation of detailed project information, tailored to the user's specifications.
    public func customProjectInfo(project: SceneProjectInfo) -> any View {
        let sessionId: String = self.sceneData.openedProject.sessionID ?? ""
        let projectid: String = self.sceneData.projectGUIDs[project.name] ?? ""
        return VStack(alignment: .leading) {
            Text("SessionID: \(sessionId.prefix(min(sessionId.count, 16)))...")
            Text("ProjectID: \(projectid.prefix(min(projectid.count, 16)))...")
        }
    }
    
    /// Loads saved models stored in device storage to the loaded project.
    public func loadSavedModels() {
        if !self.sceneData.openedProject.loaded || self.sceneData.exportedModelsURL == nil {
            return
        }
        
        DispatchQueue.main.async {
            for modelType in SceneModelData.SceneModelType.allCases {
                if modelType == .alignment { continue }
                let checkUrl = self.sceneData.exportedModelsURL!.appendDir(dirName: self.sceneData.openedProject.name).appendDir(dirName: modelType.rawValue)
                
                if FileManager.default.fileExists(atPath: checkUrl.getPath()) {
                    let checkModelUrl = checkUrl.appendFile(fileName: "model.obj")
                    
                    if FileManager.default.fileExists(atPath: checkModelUrl.getPath()) {
                        self.sceneModelData.savedModels[modelType] = checkModelUrl
                    }
                } else { self.sceneModelData.savedModels[modelType] = nil }
            }
        }
    }
    
    /// Requests a refresh or reconstruction of a model specified by `modelType`, updating or recreating its data.
    public func refreshModel(modelType: SceneModelData.SceneModelType) {
        self.sceneModelData.savedModels[modelType] = nil
        self.pushCommand(command: CalculateModel(modelType: modelType))
    }
    
    /// Initiates the upload of media files specified in `files` to the reconstruction software.
    public func uploadMedia(files: Set<DocURL>, waitDownload: Set<MediaUploadState.DownloadFileData>) {
        self.pushCommand(command: StartMediaUpload(savedFiles: files, waitDownload: waitDownload))
    }
    
    /// Manages various actions related to media upload within the application. This method unifies the control of upload processes, allowing the user to resume, pause, or completely stop media uploads. This design simplifies the interface for handling upload actions, making it easier to manage network resources and user interactions with ongoing uploads.
    public func manageUpload(action: MediaTransferAction) {
        if self.sceneData.mediaUploadState != nil {
            switch action {
            case .resumeTransfer:
                self.pushCommand(command: StartMediaUpload(savedFiles: []))
            case .pauseTransfer:
                self.nodeConnection?.sendFileCancel()
                self.sceneData.mediaUploadState!.transferPaused = true
                self.sceneData.mediaUploadState!.transferedBytes -= self.sceneData.mediaUploadState!.currentFileOffset
                self.sceneData.mediaUploadState!.currentFileOffset = 0
            case .stopTransfer:
                let waitDownload = Set(self.sceneData.mediaUploadState?.waitDownload.compactMap({ $0.fileName }) ?? [])
                if !waitDownload.isEmpty {
                    CRFly.shared.droneController.uploadCanceledFor(fileNames: waitDownload)
                }
                
                self.nodeConnection?.sendFileCancel()
                self.sceneData.mediaUploadState = nil
            }
        }
    }
    
    /// Handler for when downloads are canceled, listing affected files.
    public func downloadCanceledFor(fileNames: Set<String>) {
        if self.sceneData.mediaUploadState != nil {
            self.sceneData.mediaUploadState!.transferPaused = true
            self.sceneData.mediaUploadState!.transferForcePaused = true
            
            for fileName in fileNames {
                let found = self.sceneData.mediaUploadState!.waitDownload.first(where: { $0.fileName == fileName })
                if found != nil {
                    self.sceneData.mediaUploadState!.waitDownload.remove(found!)
                    self.sceneData.mediaUploadState!.totalMedia -= 1
                    self.sceneData.mediaUploadState!.totalBytes -= found!.fileSize
                }
            }
            self.pushCommand(command: StartMediaUpload(startIfUserPaused: false))
        }
    }
    
    /// Prepares the specified file for uploading, potentially marking it as a temporary download.
    public func readyToUpload(fileURL: DocURL, fileName: String) {
        if self.sceneData.mediaUploadState != nil, CRFly.shared.albumSavedController.albumSavedData.savedMediaURL != nil {
            let found = self.sceneData.mediaUploadState!.waitDownload.firstIndex(where: { $0.fileName == fileName })
            if found != nil {
                self.pushCommand(command: StartMediaUpload(savedFiles: [fileURL], startIfUserPaused: false))
            }
        }
    }
    
    // MARK: HTTPConnectionStateObserver methods
    
    /// Handles state changes in the HTTP connection, managing tasks based on the new state.
    public func observeConnection(newState: HTTPConnection.HTTPConnectionState) {
        DispatchQueue.main.async {
            switch newState {
            case .connected:
                self.sceneData.sceneConnected = true
                self.sceneData.sceneConnLost = false
                self.commandExecutionEnabled = true
                self.nodeAutoUpdateIdentifier += 1
                self.nodeAutoUpdate(identifier: self.nodeAutoUpdateIdentifier)
            case .disconnected:
                self.sceneData.sceneConnected = false
                self.sceneData.sceneConnLost = false
                self.commandExecutionEnabled = false
                self.projectUnload()
                self.nodeConnection?.removeStateChangeObserer(observer: self)
                self.nodeConnection = nil
                self.availableSessions = 0
                self.sceneData.projectList.removeAll()
                self.sceneData.mediaUploadState = nil
            case .lost:
                self.sceneData.sceneConnLost = true
                self.commandExecutionEnabled = false
            case .started: break
            }
        }
    }
    
    // MARK: Extension functions
    
    /// Returns a string that uniquely identifies the observer.
    public func getUniqueId() -> String {
        Foundation.UUID().uuidString
    }
    
    /// Manages the unloading of the current project. This function resets the project-related data stored in the scene, ensuring that all references and states associated with the previous project are cleared and no residual data remains.
    public func projectUnload() {
        self.sceneData.openedProject = SceneProjectInfo()
        self.sceneData.mediaUploadState = nil
        self.sceneModelData.pointCloud = []
        self.sceneModelData.alignmentCameras = []
        self.sceneModelData.savedModels = [:]
    }
    
    /// Constructs an HTTP request with specific parameters suitable for communication with the RCNode.
    public func constructHTTPRequest(path: String, method: HTTPRequest.Method = .get, data: String? = nil, authToken: String? = nil) -> HTTPRequest {
        var headers = ["Authorization": "Bearer \(authToken ?? self.nodeAuthToken)"]
        if self.sceneData.openedProject.sessionID != nil {
            headers["Session"] = "\(self.sceneData.openedProject.sessionID!)"
        }
        if method == .post, data != nil {
            headers["Content-Type"] = "application/octet-stream"
            headers["Content-Length"] = "\(data!.lengthOfBytes(using: .utf8))"
        }
        return HTTPRequest(urlPath: path, method: method, headers: headers, body: data)
    }
    
    /// Attempts to establish a network connection to an RCNode using a list of possible addresses and a specific authentication token.
    public func startConnectionTo(addresses: [String], authToken: String) async -> Bool {
        await withTaskGroup(of: (Bool, String, String).self, body: { group in
            for address in addresses {
                group.addTask {
                    do {
                        let httpcon = try await HTTPConnection(host: address, port: 8000, connectionTimeout: 2, keepAlive: false)
                        let data = try await httpcon.send(request: self.constructHTTPRequest(path: "/node/connectuser", authToken: authToken))
                        httpcon.terminateConnection()
                        return (HTTPResponseParser(data: data)?.statusCode == 200, address, authToken)
                    } catch { return (false, address, authToken) }
                }
            }
            
            for await result in group {
                if result.0 {
                    do {
                        let newConnection = try await HTTPConnection(host: result.1, port: 8000, connectionTimeout: 10, keepAlive: true)
                        group.cancelAll()
                        DispatchQueue.main.async {
                            self.nodeConnection = newConnection
                            self.nodeAuthToken = result.2
                            newConnection.addStateChangeObserver(observer: self)
                        }
                        return true
                    } catch { return false }
                }
            }
            return false
        })
    }
    
    /// Observes changes to the output folder on the RCNode, typically used for download of exported models.
    public func observeOutputFolder(files: [String]) {
        let exportReady = self.sceneData.openedProject.exportModelReady
        if exportReady != nil {
            if files.contains("\(exportReady!.rawValue).zip") {
                self.pushCommand(command: DownloadModel(modelType: exportReady!))
                self.sceneData.openedProject.exportModelReady = nil
            }
        }
        
        for modelType in SceneModelData.SceneModelType.allCases {
            if modelType == .alignment { continue }
            
            if self.sceneModelData.savedModels[modelType] == nil, files.contains("\(modelType.rawValue).zip") {
                self.pushCommand(command: DownloadModel(modelType: modelType))
            }
        }
    }
    
    /// Prepares the node for auto-updating based on the current state or tasks.
    private func nodeAutoUpdate(identifier: Int) {
        if self.nodeAutoUpdateIdentifier == identifier, self.commandExecutionEnabled {
            if self.sceneData.openedProject.waitingOnTask.count != 0 {
                self.pushCommand(command: GetProjectTasks())
                self.pushCommand(command: GetProjectStatus())
            } else if getCommandInQueueCount() == 0 {
                self.pushCommand(command: (self.sceneData.openedProject.loaded) ? GetProjectStatus() : GetNodeStatus())
            }
            
            let deadline: DispatchTime = .now() + (self.appInBackground ? self.bckgUpdateTimeout : self.autoUpdateTimeout)
            DispatchQueue.main.asyncAfter(deadline: deadline) {
                self.nodeAutoUpdate(identifier: identifier)
            }
        }
    }
}
