import Foundation

/**
 `ExportSelectedModel` is a command class that handles the exporting of selected 3D models into specified formats such as OBJ files compressed into ZIP archives. It extends `ProjectCLICommand` to utilize structured CLI commands for executing specific tasks related to model export.

 - Supported Model Types and Their Export Formats:
   Depending on the `SceneModelData.SceneModelType` provided, the class configures a specific path and parameters for the command that triggers the export process in the RealityCapture Node. Currently, it supports exporting to formats like OBJ contained in ZIP files.
 */
public class ExportSelectedModel: ProjectCLICommand {
    /// A string representing the filename under which the exported model will be saved. This is determined by querying the `RCNodeController` for the appropriate model filename based on the specified model type.
    private var filename = ""

    /// A `SceneModelData.SceneModelType` that represents model type of object being exported.
    private var modelType: SceneModelData.SceneModelType

    /// Initializes an `ExportSelectedModel` instance based on the specified model type. It constructs a CLI command structure for exporting the model and uses this structure to initialize the superclass.
    public init(modelType: SceneModelData.SceneModelType) {
        self.filename = CRFly.shared.sceneController.sceneModelData.sceneModelType.rawValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        self.modelType = modelType

        let cliStructure = CLIStructure(path: "/project/command?name=exportModelToZip&param1=\(filename).zip&param2=obj", method: .get, errorTitle: "Error Exporting \(modelType.rawValue)", taskName: "SelectModelExport", taskDescription: "Exporting Selected Model...", doWhenDone: DownloadModel(modelType: modelType))

        super.init(cliStructure: cliStructure)
    }

    /// Overrides the `execute` method to check if a filename has been successfully set before proceeding. If no filename is set, it skips the operation; otherwise, it calls the superclass's `execute` method to perform the export.
    override public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        if self.filename == "" {
            completion(true, false, nil)
        } else {
            super.execute(completion: { v1, v2, v3 in
                DispatchQueue.main.async {
                    if v1 {
                        self.sceneController.sceneData.openedProject.exportModelReady = self.modelType
                    }
                }
                completion(v1, v2, v3)
            })
        }
    }
}
