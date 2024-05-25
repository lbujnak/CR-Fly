import Foundation

/**
 `SimplifyAndExportModel` is a specialized command that integrates with the RealityCapture Node to simplify the export of 3D model. It extends `ProjectCLICommand` to utilize structured CLI commands for executing model simplification and export tasks.

 - Usage: `SimplifyAndExportModel` is used when there is a need to simplify a 3D model and subsequently export it. This command is part of a sequence of operations in the RealityCapture environment, ensuring that models are processed and simplified before export.

 The command plays a crucial role in applications that require detailed processing and exporting of 3D models, especially in environments where model simplification is necessary to optimize performance or meet specific requirements.
 */
public class SimplifyAndExportModel: ProjectCLICommand {
    /// Initializes an `ExportSelectedModel` instance based on the specified model type. It constructs a CLI command structure for exporting the model and uses this structure to initialize the superclass.
    public init(modelType: SceneModelData.SceneModelType) {
        let cliStructure = CLIStructure(path: "/project/command?name=simplify", method: .get, errorTitle: "Error Simplifying \(modelType.rawValue)", taskName: "SimplifyExportModel", taskDescription: "Simplifying Exported Model...", doWhenDone: ExportSelectedModel(modelType: modelType))
        super.init(cliStructure: cliStructure)
    }
}
