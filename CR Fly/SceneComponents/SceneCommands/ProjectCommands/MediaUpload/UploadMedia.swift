import SwiftUI

/**
 `UploadMedia` is a command class responsible for handling the upload of media files to a remote server. It integrates with system components to manage network connections, track upload progress, and handle potential errors during the upload process.
 */
public class UploadMedia: Command {
    /// Reference to an instance of `SceneController` that manages broader scene-related operations.
    private let sceneController = CRFly.shared.sceneController as! RCNodeController
    
    /// Executes the media uploading process by managing the upload of selected media files to a remote server (RCNode). This method ensures that all prerequisites for a successful upload are met before proceeding, handles the upload of each file, and provides feedback through the system's user interface.
    public func execute(completion: @escaping (Bool, Bool, (String, String)?) -> Void) {
        if !self.sceneController.sceneData.openedProject.loaded ||
            self.sceneController.sceneData.mediaUploadState == nil || self.sceneController.sceneData.mediaUploadState!.transferPaused {
            completion(true, false, nil)
        } else if self.sceneController.sceneData.mediaUploadState!.uploadSet.count == 0 {
            if self.sceneController.sceneData.mediaUploadState!.waitDownload.count == 0 {
                self.sceneController.sceneData.mediaUploadState = nil
            } else {
                self.sceneController.sceneData.mediaUploadState!.transferPaused = true
                self.sceneController.sceneData.mediaUploadState!.transferForcePaused = true
            }
            completion(true, false, nil)
        } else {
            self.sceneController.sceneData.mediaUploadState!.currentFileOffset = 0
            let uploadFile = self.sceneController.sceneData.mediaUploadState!.uploadSet.first!
            
            let uploadFileName = uploadFile.getFileNameWithout(prefix: "_tmp.")
            let removeFileAfterUpload = uploadFile.getFileName() != uploadFileName
            
            Task {
                do {
                    // Send and check response
                    let request = self.sceneController.constructHTTPRequest(path: "/project/command?name=add&param1=\(uploadFileName)", method: .post)
                    let data = try await self.sceneController.nodeConnection?.sendFile(request: request, fileURL: uploadFile, byteUploadedUpdate: { uploadedBytes in
                        DispatchQueue.main.async {
                            if self.sceneController.sceneData.mediaUploadState?.transferPaused ?? true {
                                self.sceneController.nodeConnection?.sendFileCancel()
                                
                                self.sceneController.sceneData.mediaUploadState?.transferedBytes -= self.sceneController.sceneData.mediaUploadState?.currentFileOffset ?? 0
                                self.sceneController.sceneData.mediaUploadState?.currentFileOffset = 0
                            } else {
                                self.sceneController.sceneData.mediaUploadState?.transferedBytes += uploadedBytes
                                self.sceneController.sceneData.mediaUploadState?.currentFileOffset += uploadedBytes
                            }
                        }
                    })
                    
                    guard let data, let parsedResponse = HTTPResponseParser(data: data) else {
                        completion(false, false, ("Error Uploading Media to RC", "An issue was encountered while parsing the response from RCNode."))
                        return
                    }
                    
                    let jsonData = parsedResponse.bodyTo2DJSON()
                        
                    guard let status = jsonData!["taskID"] as? String else {
                        DispatchQueue.main.async {
                            self.sceneController.sceneData.mediaUploadState?.transferPaused = true
                        }
                            
                        var errorDescription = "The response from RCNode was invalid. The structure of the response does not align with the expected API format."
                        
                        if let error = jsonData!["code"] as? Int, let errorMsg = jsonData!["message"] as? String {
                            errorDescription = "An issue was encountered while parsing the response from RCNode, error(\(error)): \(errorMsg)"
                        }
                        completion(false, false, ("Error Uploading Media to RC", errorDescription))
                        return
                    }
                        
                    let taskStatus = SceneProjectInfo.TaskStatus(taskName: "Add File To Project", taskDescription: "Adding file to project...")
                        
                    DispatchQueue.main.async {
                        if removeFileAfterUpload {
                            try? uploadFile.removeItem()
                        }
                        
                        self.sceneController.sceneData.openedProject.fileList.insert(uploadFileName)
                        self.sceneController.sceneData.mediaUploadState?.transferedMedia += 1
                        self.sceneController.sceneData.mediaUploadState?.uploadSet.remove(uploadFile)
                        
                        self.sceneController.pushCommand(command: UploadMedia())
                        self.sceneController.sceneData.openedProject.waitingOnTask[status] = (CalculateModel(modelType: .alignment), taskStatus)
                    }
                    completion(true, false, nil)
                } catch {
                    DispatchQueue.main.async {
                        self.sceneController.sceneData.mediaUploadState?.transferPaused = true
                    }
                    
                    completion(false, true, ("Error Uploading Media to RC", "An issue occurred while sending the request, error: \(error.localizedDescription)"))
                }
            }
        }
    }
}
