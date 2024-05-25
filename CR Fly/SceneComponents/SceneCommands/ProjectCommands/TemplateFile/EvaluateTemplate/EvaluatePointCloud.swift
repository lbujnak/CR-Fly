import Foundation

/**
 `EvaluatePointCloud`  is a command class that extends `ProjectCLICommand` that orchestrates the export of point cloud data from a RealityCapture Node (RCNode). The class is designed to export a detailed point cloud report that is essential for 3D data analysis and visualization.
 
 - Command Flow:
    - Initially, the command requests the RCNode to export the point cloud data, defined by a template file (`crfly-pointcloud.tpl`). Following a successful export, a `DownloadTemplateExport` command is triggered to download the generated JSON file that includes the point cloud data.
 */
public class EvaluatePointCloud: ProjectCLICommand {
    /// Sets up the necessary command structure to initiate the export of point cloud data from the RCNode, incorporating dynamic construction of the export file name using the project's GUID and scheduling the subsequent download operation.
    public init() {
        let sceneController = CRFly.shared.sceneController
        let projectID = sceneController.sceneData.projectGUIDs[sceneController.sceneData.openedProject.name] ?? ""
        
        let evalPointCloudExportFile = "crfly-pointcloud(\(projectID)).json"
        let evalPointCloudDownload = DownloadTemplateExport(file: evalPointCloudExportFile, templateFileType: .pointCloud)
        let evalPointCloudCLIStructure = ProjectCLICommand.CLIStructure(path: "/project/command?name=exportReport&param1=\(evalPointCloudExportFile)&param2=crfly-pointcloud.tpl", method: .get, errorTitle: "Error Evaluating Template File (Point Cloud Export)", taskName: "Evaulate Point Cloud", taskDescription: "Exporting point cloud...", doWhenDone: evalPointCloudDownload)
        super.init(cliStructure: evalPointCloudCLIStructure)
    }
}
