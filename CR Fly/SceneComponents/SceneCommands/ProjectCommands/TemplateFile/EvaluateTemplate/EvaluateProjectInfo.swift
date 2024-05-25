import Foundation

/**
 `EvaluateProjectInfo`  is a command class that extends `ProjectCLICommand` to handle the evaluation and export of project information from a RealityCapture Node (RCNode). It is used to generate a detailed report based on the current project's data.
 
 - Command Flow:  The command first initiates an export operation for the project information, which is defined by a template file (`crfly-projectinfo.tpl`). Upon successful completion of the export, a `DownloadTemplateExport` command is initiated to download the resulting JSON file containing the exported project information.
 */
public class EvaluateProjectInfo: ProjectCLICommand {
    /// Initializes an `EvaluateProjectInfo` object by setting up the command structure required to export the project information report from the RCNode. It dynamically constructs the export file name using the project's GUID and sets up the subsequent download operation.
    public init() {
        let sceneController = CRFly.shared.sceneController
        let projectID = sceneController.sceneData.projectGUIDs[sceneController.sceneData.openedProject.name] ?? ""
        
        let evalInfoExportFile = "crfly-projectinfo(\(projectID))).json"
        let evalInfoDownload = DownloadTemplateExport(file: evalInfoExportFile, templateFileType: .projectInfo)
        let evalInfoCLIStructure = ProjectCLICommand.CLIStructure(path: "/project/command?name=exportReport&param1=\(evalInfoExportFile)&param2=crfly-projectinfo.tpl", method: .get, errorTitle: "Error Evaluating Template File (Project Information Export)", taskName: "Evaulate Project Info", taskDescription: "Exporting project information...", doWhenDone: evalInfoDownload)
        super.init(cliStructure: evalInfoCLIStructure)
    }
}
