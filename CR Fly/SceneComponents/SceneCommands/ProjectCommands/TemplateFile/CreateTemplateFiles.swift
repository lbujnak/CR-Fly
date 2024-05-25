import Foundation

/**
 `CreateTemplateFiles` is a class that encapsulates the functionality to create and upload specialized template files used in RealityCapture projects. It interacts with a scene controller to manage commands that upload these templates to a RealityCapture Node (RCNode). Each template file is designed to export specific types of data from RealityCapture.
 
 - Template Descriptions:
     - **Project Information Template**: Exports various metrics about the project such as image count, component count, point count, camera count, and measurement count. This template is crucial for generating reports that provide an overview of project statistics.
     - **Point Cloud Template**: Facilitates the export of point cloud data with specific filters and formatting, useful for downstream processing or visualization.
     - **Camera Alignment Template**: Exports camera alignment data which is essential for understanding camera positions and orientations relative to the reconstructed 3D space.
 */
public class CreateTemplateFiles: Command {
    /// Reference to an instance of `SceneController` that manages broader scene-related operations.
    private let sceneController = CRFly.shared.sceneController
    
    /// Executes the process of generating and uploading template files. It constructs three different templates for exporting project information, point clouds, and camera alignments, and then schedules them for upload to the RCNode.
    public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        let getProjectInfoTemplate = "$Using(\"CapturingReality.Report.ProjectInformationExportFunctionSet\")$Using(\"CapturingReality.Report.SfmExportFunctionSet\"){$ExportProjectInfo(\"imageCount\":$(imageCount), \"componentCount\":$(componentCount), \"pointCount\": $(pointCount),\"cameraCount\": $(cameraCount), \"measurementCount\": $(measurementCount), \"displayScale\":$(displayScale)) }"
        let postInfoStructure = RCNodeCommand.Structure(path: "/project/upload?name=crfly-projectinfo.tpl&folder=output", method: .post, data: getProjectInfoTemplate, dataOutputType: .none, acceptStatusCode: 200, errorTitle: "Error Uploading Template File (Project Information Export) to RCNode")
        
        let getPointCloudTemplate = "$Using(\"CapturingReality.Report.SfmExportFunctionSet\")$ExportPointsEx(\"weak|ill|outlier\",0,999999,$(aX:.4),$(aY:.4),$(aZ:.4),$(r:c),$(g:c),$(b:c),)$Strip(1)"
        let postPCloudStructure = RCNodeCommand.Structure(path: "/project/upload?name=crfly-pointcloud.tpl&folder=output", method: .post, data: getPointCloudTemplate, dataOutputType: .none, acceptStatusCode: 200, errorTitle: "Error Uploading Template File (PointCloud Export) to RCNode")
        
        let getAlignCamerasTemplate = "$Using(\"CapturingReality.Report.SfmExportFunctionSet\")$ExportCameras($(invYaw:.4),$(invPitch:.4),$(invRoll:.4),$(aX:.4),$(aY:.4),$(aZ:.4),)$Strip(1)"
        let alignCamStructure = RCNodeCommand.Structure(path: "/project/upload?name=crfly-aligncameras.tpl&folder=output", method: .post, data: getAlignCamerasTemplate, dataOutputType: .none, acceptStatusCode: 200, errorTitle: "Error Uploading Template File (Camera Export) to RCNode")
        
        self.sceneController.pushCommand(command: ProjectCommand(structure: postInfoStructure, requestedProjectState: .opened, executionDisableInteraction: false))
        
        self.sceneController.pushCommand(command: ProjectCommand(structure: postPCloudStructure, requestedProjectState: .opened, executionDisableInteraction: false))
        
        self.sceneController.pushCommand(command: ProjectCommand(structure: alignCamStructure, requestedProjectState: .opened, executionDisableInteraction: false))
        
        completion(true, false, nil)
    }
}
