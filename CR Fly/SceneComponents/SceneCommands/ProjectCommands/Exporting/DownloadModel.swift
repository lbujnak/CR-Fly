import Foundation
import SSZipArchive

/**
 `DownloadModel` is a command class that handles the downloading and extracting of 3D models from a RCNode. It extends the `Command` protocol to utilize structured commands for performing network-based operations related to model management.
 
 - Supported Model Types: The class supports downloading models based on the `SceneModelData.SceneModelType` provided. It manages downloading ZIP files containing the 3D models and extracts them to a specified location.
 */
public class DownloadModel: Command {
    /// Reference to the `ViewController` responsible for managing navigation, presentation of different views within the application and displaying errors.
    private let viewController = CRFly.shared.viewController
    
    /// Reference to an instance of `SceneController` that manages broader scene-related operations.
    private let sceneController = CRFly.shared.sceneController as! RCNodeController
    
    /// A `SceneModelData.SceneModelType` that represents model type of object being exported.
    private let modelType: SceneModelData.SceneModelType
    
    /// Initializes a `DownloadModel` instance with a specified model type. 
    public init(modelType: SceneModelData.SceneModelType) {
        self.modelType = modelType
    }
    
    /// Executes the model download process from a remote server (RCNode).
    public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        if !self.sceneController.sceneData.sceneConnected || self.sceneController.nodeConnection == nil || self.sceneController.sceneData.exportedModelsURL == nil || !self.sceneController.sceneData.openedProject.loaded || self.modelType == .alignment {
            completion(true, false, nil)
        } else {
            DispatchQueue.main.async {
                self.sceneController.sceneData.openedProject.projectUpdateState = .downloadLoadModel(self.modelType)
                self.sceneController.sceneModelData.savedModels[self.modelType] = nil
            }
            
            Task {
                do {
                    let filename = self.modelType.rawValue
                    
                    if filename == "" {
                        completion(false, false, ("Error Downloading \(self.modelType.rawValue)", "Undefined filename for download."))
                        return
                    }
                    
                    let projectUrl = self.sceneController.sceneData.exportedModelsURL!.appendDir(dirName: self.sceneController.sceneData.openedProject.name)
                    
                    try projectUrl.createItem(withIntermediateDirectories: true)
                    
                    let request = self.sceneController.constructHTTPRequest(path: "/project/download?name=\(filename.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!).zip&folder=output", method: .get)
                    
                    let data = try await self.sceneController.nodeConnection?.downloadFile(request: request, dirURL: projectUrl, fileName: "\(filename).zip")
                    
                    guard let data else {
                        completion(false, true, ("Error Downloading \(self.modelType.rawValue)", "Connection with RealityCapture is not established."))
                        return
                    }
                    
                    if let parsedResponse = HTTPResponseParser(data: data) {
                        if parsedResponse.statusCode != 200 {
                            completion(false, false, ("Error Downloading \(self.modelType.rawValue)", "An issue was encountered while parsing the response from RCNode. Status Code: \(parsedResponse.statusCode) with message: \(parsedResponse.bodyTo2DJSON()?["message"] ?? "Unknown")."))
                            return
                        }
                        
                        let atUrl = projectUrl.appendFile(fileName: "\(filename).zip")
                        let destinationUrl = projectUrl.appendDir(dirName: filename)
                        
                        try destinationUrl.removeItem()
                        
                        SSZipArchive.unzipFile(atPath: atUrl.getPath(), toDestination: destinationUrl.getPath())
                        try atUrl.removeItem()
                        
                        DispatchQueue.main.async {
                            self.sceneController.sceneModelData.savedModels[self.modelType] = destinationUrl.appendFile(fileName: "model.obj")
                        }
                        completion(true, false, nil)
                    } else {
                        completion(false, false, ("Error Downloading \(self.modelType.rawValue)", "An issue was encountered while parsing the response from RCNode."))
                        return
                    }
                    DispatchQueue.main.async {
                        self.sceneController.sceneData.openedProject.projectUpdateState = nil
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.sceneController.sceneData.openedProject.projectUpdateState = nil
                    }
                    completion(false, true, ("Error Downloading \(self.modelType.rawValue)", "An issue occurred while sending the request, error: \(error.localizedDescription)"))
                }
            }
        }
    }
}
