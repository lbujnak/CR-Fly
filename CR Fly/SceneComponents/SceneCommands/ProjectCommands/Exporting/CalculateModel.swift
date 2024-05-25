import Foundation

/**
 `CalculateModel` is a specialized command that orchestrates a sequence of operations to calculate various types of 3D models in a RealityCapture Node. It extends `ProjectCLICommand` to utilize structured CLI commands for executing specific model calculation tasks.

 - Supported Model Types:
   - `alignment`: Triggers a sequence to align images.
   - `preview`: Sets up commands to calculate a preview model.
   - `normal`: Configures tasks to calculate a normal model.
   - `colorized`: Prepares commands to calculate a texture model.

 - Task Sequence: Depending on the model type, different CLI structures are initialized with specific paths, methods, and subsequent tasks that define a workflow. For example, calculating a texture model might involve setting a reconstruction region, selecting triangles within that region, and then proceeding with the texture calculation.
 */
public class CalculateModel: ProjectCLICommand {
    ///  An array of strings that lists the names of the tasks that should be checked for completion before executing this command. This ensures that no overlapping or redundant tasks are executed.
    private var taskNameCheck: [String] = []

    /// Initializes a `CalculateModel` instance based on the specified model type. Depending on the model type, a sequence of CLI commands is set up to perform necessary preliminary tasks before the actual model calculation.
    public init(modelType: SceneModelData.SceneModelType) {
        var url = ""
        switch modelType {
        case .alignment:
            break
        case .preview:
            url = "calculatePreviewModel"
        case .normal:
            url = "calculateNormalModel"
        case .colorized:
            url = "calculateTexture"
        }

        if url == "" {
            let cliStructure = CLIStructure(path: "/project/command?name=align", method: .get, errorTitle: "Error Aligning Images", taskName: "Align Images", taskDescription: "Aligning Images into Point Cloud...", doWhenDone: GetProjectStatus())
            self.taskNameCheck = ["Align Images", "Add File To Project"]
            super.init(cliStructure: cliStructure)
        } else {
            let calculateModel = CLIStructure(path: "/project/command?name=\(url)", method: .get, errorTitle: "Error Calculating \(modelType.rawValue)", taskName: "Calculating Model", taskDescription: "Calculating \(modelType.rawValue)...", doWhenDone: CRFly.shared.sceneController.sceneData.openedProject.pointCnt! > 100_000 ? SimplifyAndExportModel(modelType: modelType) : ExportSelectedModel(modelType: modelType))

            let selectTrianglesInsideReconReg = CLIStructure(path: "/project/command?name=selectTrianglesInsideReconReg", method: .get, errorTitle: "Error Selectiong Triangles Inside Reconstruction Region", taskName: "SelectTrianglesInsideReconReg", taskDescription: "Selectiong Triangles Inside Reconstruction Region...", doWhenDone: ProjectCLICommand(cliStructure: calculateModel))

            let setReconRegionAuto = CLIStructure(path: "/project/command?name=setReconstructionRegionAuto", method: .get, errorTitle: "Error Setting Reconstruction Region Auto", taskName: "SetReconRegionAuto", taskDescription: "Setting Reconstruction Region to Auto ...", doWhenDone: ProjectCLICommand(cliStructure: selectTrianglesInsideReconReg))

            self.taskNameCheck = ["Calculating Model", "SelectTrianglesInsideReconReg", "SetReconRegionAuto"]
            super.init(cliStructure: setReconRegionAuto)
        }
    }

    /// Overrides the `execute` method to perform a pre-execution check that ensures no conflicting tasks are currently active. If conditions are met, the command proceeds with its execution sequence, potentially chaining several tasks.
    override public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        if self.sceneController.sceneData.mediaUploadState == nil, !self.sceneController.sceneData.openedProject.waitingOnTask.contains(where: { taskNameCheck.contains($0.value.1.taskName) }) {
            super.execute(completion: completion)
        } else {
            completion(true, false, nil)
        }
    }
}
