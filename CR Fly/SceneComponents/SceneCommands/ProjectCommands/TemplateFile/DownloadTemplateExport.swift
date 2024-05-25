import SwiftUI

/**
 `DownloadTemplateExport` is a command class that extends `ProjectCommand` to handle the downloading of specific template export files from a RealityCapture Node (RCNode). This class is used to retrieve and process exported data such as project information, point clouds, and camera alignment data.
 */
public class DownloadTemplateExport: ProjectCommand {
    /// Enumerates the types of template files that can be requested for download, which include:
    public enum TemplateFileType: String {
        /// Template for exporting project information.
        case projectInfo = "Project Information"
        
        /// Template for exporting point cloud data.
        case pointCloud = "Point Cloud"
        
        /// Template for exporting camera alignment data.
        case alignCameras = "Alignment Cameras"
    }
    
    /// An enumeration `TemplateFileType` that specifies the type of template file to be downloaded, influencing the processing logic and completion actions based on the file type.
    private let templateFileType: TemplateFileType
    
    ///  Initializes a `DownloadTemplateExport` object with the specified file and template type. It sets up the required download parameters and command structure.
    public init(file: String, templateFileType: TemplateFileType) {
        self.templateFileType = templateFileType
        let structure = Structure(path: "/project/download?name=\(file)&folder=output", method: .get, dataOutputType: .none, acceptStatusCode: 200, errorTitle: "Error Downloading Template Export (\(templateFileType.rawValue)) from RCNode")
        super.init(structure: structure, requestedProjectState: .opened, executionDisableInteraction: false)
    }
    
    /// Overrides the base execute method to handle the download operation, setting the project update state, and processing the downloaded data based on the template type.
    override public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        self.sceneController.sceneData.openedProject.projectUpdateState = .fetchDataFromExports
        super.execute(completion: { v1, v2, v3 in
            DispatchQueue.main.async {
                self.sceneController.sceneData.openedProject.projectUpdateState = nil
                if self.templateFileType == .projectInfo {
                    self.sceneController.sceneData.openedProject.readyToUpload = true
                }
            }
            completion(v1, v2, v3)
        })
    }
    
    /// Processes the HTTP response after a successful download. It extracts and uses the data based on the specified `templateFileType`.
    override internal func validResponseAction(parsedResponse: HTTPResponseParser, completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        if self.templateFileType == .projectInfo {
            let jsonData = parsedResponse.bodyTo2DJSON()
            
            guard let imageCount = jsonData!["imageCount"] as? Int,
                  let componentCount = jsonData!["componentCount"] as? Int,
                  let pointCount = jsonData!["pointCount"] as? Int,
                  let cameraCount = jsonData!["cameraCount"] as? Int,
                  let displayScale = jsonData!["displayScale"] as? Double,
                  let measurementCount = jsonData!["measurementCount"] as? Int
            else {
                completion(false, false, ("Error Downloading Template Export (\(self.templateFileType.rawValue)) from RCNode", "The response from RCNode was invalid. The structure of the response does not align with the expected API format."))
                return
            }
            
            DispatchQueue.main.async {
                if pointCount != self.sceneController.sceneData.openedProject.pointCnt {
                    self.sceneController.pushCommand(command: EvaluatePointCloud())
                }
                
                if cameraCount != self.sceneController.sceneData.openedProject.cameraCnt {
                    self.sceneController.pushCommand(command: EvaluateAlignmentCameras())
                }
                
                self.sceneController.sceneData.openedProject.imageCnt = imageCount
                self.sceneController.sceneData.openedProject.componentCnt = componentCount
                self.sceneController.sceneData.openedProject.pointCnt = pointCount
                self.sceneController.sceneData.openedProject.cameraCnt = cameraCount
                self.sceneController.sceneModelData.displayScale = Float(displayScale)
                self.sceneController.sceneData.openedProject.measurementCnt = measurementCount
            }
        } else if self.templateFileType == .pointCloud || self.templateFileType == .alignCameras {
            let pts_data = String(data: parsedResponse.body, encoding: .utf8)!
            let components = pts_data.components(separatedBy: ",")
            let dS = self.sceneController.sceneModelData.displayScale
            
            if self.templateFileType == .pointCloud, self.sceneController.sceneData.openedProject.pointCnt ?? 0 > 0 {
                var point_cloud: [MeshRendererView.PointVertex] = []
                for i in stride(from: 0, through: components.count - 6, by: 6) {
                    point_cloud.append(MeshRendererView.PointVertex(x: Float(components[i + 1])! * dS, y: Float(components[i + 2])! * dS, z: Float(components[i])! * dS, r: (Float(components[i + 3])! / 255.0), g: (Float(components[i + 4])! / 255.0), b: (Float(components[i + 5])! / 255.0)))
                }
                
                DispatchQueue.main.async {
                    self.sceneController.sceneModelData.pointCloud.removeAll()
                    self.sceneController.sceneModelData.pointCloud.append(contentsOf: point_cloud)
                }
            } else if self.templateFileType == .alignCameras, sceneController.sceneData.openedProject.cameraCnt ?? 0 > 0 {
                var align_cameras: [MeshRendererView.CameraVertex] = []
                for i in stride(from: 0, through: components.count - 1, by: 6) {
                    align_cameras.append(MeshRendererView.CameraVertex(yaw: Float(components[i])!, pitch: Float(components[i + 1])!, roll: Float(components[i + 2])!, x: Float(components[i + 3])! * dS, y: Float(components[i + 4])! * dS, z: Float(components[i + 5])! * dS))
                }
                DispatchQueue.main.async {
                    self.sceneController.sceneModelData.alignmentCameras.removeAll()
                    self.sceneController.sceneModelData.alignmentCameras.append(contentsOf: align_cameras)
                }
            }
        }
        completion(true, false, nil)
    }
}
