import Foundation

/**
 `EvaluateAlignmentCameras` is a command class that extends `ProjectCLICommand` to manage the export of alignment camera data from a RealityCapture Node (RCNode). It is specifically used to handle the extraction and subsequent downloading of camera alignment information, which is vital for accurate 3D reconstructions and analyses.
 
 - Command Flow:
    - The command triggers the RCNode to generate a report based on the alignment cameras, defined by the template file (`crfly-aligncameras.tpl`). Upon successful export, it initiates the download of the produced JSON file containing the alignment camera data.
 */
public class EvaluateAlignmentCameras: ProjectCLICommand {
    /// Configures the command to request the RCNode to export alignment camera data, constructing the file name dynamically based on the project's GUID, and sets up the subsequent download of this data.
    public init() {
        let sceneController = CRFly.shared.sceneController
        let projectID = sceneController.sceneData.projectGUIDs[sceneController.sceneData.openedProject.name] ?? ""
        
        let evalAlignCamerasExportFile = "crfly-aligncameras(\(projectID)).json"
        let evalAlignCamerasDownload = DownloadTemplateExport(file: evalAlignCamerasExportFile, templateFileType: .alignCameras)
        let evalAlignCamerasCLIStructure = ProjectCLICommand.CLIStructure(path: "/project/command?name=exportReport&param1=\(evalAlignCamerasExportFile)&param2=crfly-aligncameras.tpl", method: .get, errorTitle: "Error Evaluating Template File (Alignment Cameras Export)", taskName: "Evaulate Alignment Cameras", taskDescription: "Exporting cameras found in alignation...", doWhenDone: evalAlignCamerasDownload)
        super.init(cliStructure: evalAlignCamerasCLIStructure)
    }
}
