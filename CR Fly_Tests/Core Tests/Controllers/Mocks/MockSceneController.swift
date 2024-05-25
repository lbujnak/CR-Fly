import SwiftUI
@testable import CR_Fly

final class MockSceneController: CommandQueueController, SceneController {
    var sceneData = SceneData()
    var sceneModelData = SceneModelData()
    var speedCalcIdentifier = ""
    
    var lastUploadRequest: Set<DocURL> = []
    
    init(viewController: ViewController) {
        super.init(commandRetries: 0, commandRetryTimeout: 0, viewController: viewController)
    }
    
    func enterFromBackground() { }
    func leaveToBackground() { }
    func disconnectScene() { }
    func manageProject(action: SceneProjectAction) { }
    func manageUpload(action: MediaTransferAction) { }
    func uploadMedia(files: Set<DocURL>, waitDownload: Set<MediaUploadState.DownloadFileData>) {
        self.lastUploadRequest = files
    }
    
    func downloadCanceledFor(fileNames: Set<String>) { }
    func readyToUpload(fileURL: DocURL, fileName: String) { }
    func customProjectInfo(project: SceneProjectInfo) -> any View { EmptyView() }
    func refreshModel(modelType: SceneModelData.SceneModelType) { }
    func loadSavedModels() { }
}
