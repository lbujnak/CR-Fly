import Foundation
import SwiftUI
import DJISDK
import Photos

class LibraryCommunicationService : NSObject, DJIMediaManagerDelegate, ObservableObject {
    
    @ObservedObject private var rcProjectManager = RCNodeCommunicationService.shared.projectManagement
    
    //Global for downloading btn
    @Published var savable : Bool = false
    
    //Library View
    @Published var mediaFilter = 0 //0 - All, 1 - Photos, 2 - Videos
    @Published var mediaFetched = false
    @Published var mediaList = [DJIMediaFile]()
    @Published var mediaSections = [[DJIMediaFile]]()
    @Published var interruptThumbnailDwnld = false
    
    //Library Preview View
    @Published var mediaLibPicked : DJIMediaFile? = nil
    @Published var mediaPreviewReady = false
    @Published var mediaPreviewVideoPlaying = false
    @Published var mediaPreviewVideoCTime : Int = 0
    @Published var mediaPreviewVideoChanging : Bool = false

    //Downloading vars and stats
    @Published var mediaDownloadList = [DJIMediaFile]()
    @Published var mediaDownloading : Bool = false
    @Published var mediaDownloaded : Int = 0 {
        didSet{
            if(self.mediaDownloaded > 0){
                if(self.rcProjectManager.mediaUploading) {
                    let url = URL(fileURLWithPath: self.libraryURL.relativePath).appendingPathComponent(self.mediaDownloadList[self.mediaDownloaded-1].fileName)
                    self.rcProjectManager.sendSingleImage(path: url){ error in
                        if(error != nil){
                            GlobalAlertHelper.shared.createAlert(title: "Upload Error", msg: "Couldn't continue in upload from \(self.mediaDownloaded-1), error: \(error!)")
                            DispatchQueue.main.async { self.mediaDownloading = false }
                        }
                        
                        try! FileManager.default.removeItem(atPath: url.relativePath)
                    }
                }
            }
        }
    }
    @Published var stat_dwnBytes : Int64 = 0
    @Published var stat_totalBytes : Int64 = 0
    @Published var stat_speed : Float = 0
    
    private var drone : DJIBaseProduct? = nil
    private var camera : DJICamera? = nil
    private var changingVideoTime : Bool = false
    private var libraryURL : URL = URL(filePath: NSHomeDirectory())
    
    override init() {
        super.init()
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        self.libraryURL = URL(string: paths)!.appendingPathComponent("Saved Media")
        if !FileManager.default.fileExists(atPath: self.libraryURL.path) {
            do {
                try FileManager.default.createDirectory(atPath: self.libraryURL.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
                return
            }
        }
        self.savable = true
    }
    
    private func refreshDroneAndCamera() -> String? {
        self.drone = DJISDKManager.product()
        if(self.drone == nil){ return "Product is connected, but DJISDKManager.product() is nil" }
        
        self.camera = drone!.camera
        if(self.camera == nil){ return "Unable to detect camera" }
        
        if(!camera!.isMediaDownloadModeSupported()){ return "Product does not support media download mode" }
        
        self.camera!.mediaManager!.delegate = self
        return nil
    }
    
    func prepareFPV(completionHandler: @escaping (String?) -> Void){
        self.stopPlaybackMode(){ (error) in
            self.mediaFilter = 0
            completionHandler(error)
        }
    }
    
    func startPlaybackMode(completionHandler: @escaping (String?) -> Void){
        let err : String? = self.refreshDroneAndCamera()
        if(err != nil){
            completionHandler(err!)
            return
        }
        
        if(self.camera!.displayName == DJICameraDisplayNameZenmuseP1 || camera!.displayName == DJICameraDisplayNameMavicAir2Camera){
            self.camera!.enterPlayback(completion: {(error) in
                if (error != nil) {
                    completionHandler(error!.localizedDescription)
                    return
                }
            })
        }
        else{
            self.camera!.setMode(.mediaDownload, withCompletion: {(error) in
                if(error != nil) {
                    completionHandler(error!.localizedDescription)
                    return
                }
            })
        }
            
        self.refreshMediaList(){ (error) in
            completionHandler(error)
        }
    }
    
    private func refreshMediaList(completionHandler: @escaping (String?) -> Void){
        let manager = self.camera!.mediaManager!
        manager.refreshFileList(of: DJICameraStorageLocation.sdCard, withCompletion: { (error) in
            if(error != nil){
                completionHandler("refresh error state: \(error!.localizedDescription)")
                return
            }
            
            let files : [DJIMediaFile] = manager.sdCardFileListSnapshot() ?? []
                            
            self.mediaLibPicked = nil
            self.mediaFetched = false
            self.mediaList.removeAll()
            self.mediaSections.removeAll()
            
            var sections = 0
            for i in 0..<files.count{
                if(i == 0 || self.mediaList.last?.timeCreated.prefix(10) != files[i].timeCreated.prefix(10)){
                    self.mediaSections.append([])
                    sections += 1
                }
                
                self.mediaList.append(files[i])
                self.mediaSections[sections-1].append(files[i])
            }
                            
            if(self.mediaList.count > 0){
                self.downloadThumbnail(index: 0, retries: 0)
            }
            completionHandler(nil)
        })
    }
    
    func stopPlaybackMode(completionHandler: @escaping (String?) -> Void){
        let err : String? = self.refreshDroneAndCamera()
        
        if(err != nil){
            completionHandler(err!)
            return
        }
        
        self.camera!.exitPlayback(completion: {(error) in
            if (error != nil) {
                completionHandler("Error existing libmode: \(error!.localizedDescription)")
                return
            }
                
            self.mediaFilter = 0
            completionHandler(nil)
        })
    }
    
    private func downloadThumbnail(index: Int, retries: Int){
        if(self.interruptThumbnailDwnld){
            self.interruptThumbnailDwnld = false
            return
        }
        if(index >= self.mediaList.count){
            self.mediaFetched = true
            return
        }
        
        if(self.mediaList[index].thumbnail != nil){
            self.downloadThumbnail(index: index+1, retries: retries)
            return
        }
        
        self.mediaList[index].fetchThumbnail(completion: { (error) in
            if(error != nil ) {
                if(retries < 5){
                    sleep(2)
                    self.downloadThumbnail(index: index, retries: retries+1)
                } else {
                    GlobalAlertHelper.shared.createAlert(title: "Downloading thumbnail image error", msg: "Error message: \(error!.localizedDescription).")
                    self.mediaFetched = false
                    self.mediaList = []
                }
                return
            }
            self.downloadThumbnail(index: index+1, retries: retries)
        })
    }
    
    func prepareFileForPreview(file : DJIMediaFile){
        if(self.isVideo(file: file)){
            self.prepareVideoPreview(file: file)
        } else if(self.isPano(file: file) || self.isPhoto(file: file)){
            self.fetchPreviewFor(file: file)
        }
        self.mediaLibPicked = file
    }
    
    func exitPreviewMode(){
        if(self.mediaLibPicked != nil) { self.mediaLibPicked!.resetPreview() }
        self.mediaPreviewVideoPlaying = false
        self.mediaPreviewVideoCTime = 0
        self.mediaPreviewReady = false
        self.mediaLibPicked = nil
    }
    
    func prepareVideoPreview(file : DJIMediaFile){
        self.playVideo(videoMedia: file){ (error) in
            if(error != nil){
                GlobalAlertHelper.shared.createAlert(title: "Error", msg: "Error preparing video:  \(error!)")
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
                self.pauseVideo(){ (error) in
                    if(error != nil){
                        GlobalAlertHelper.shared.createAlert(title: "Error", msg: "Error preparing video:  \(error!)")
                        return
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                        self.mediaPreviewReady = true
                    }
                }
            }
        }
    }
    
    func fetchPreviewFor(file: DJIMediaFile){
        file.fetchPreview(completion: {(error) in
            if(error != nil){
                self.mediaLibPicked = nil
                GlobalAlertHelper.shared.createAlert(title: "Error", msg: "Error opening preview: \(error!)")
                return
            }
            self.mediaPreviewReady = true
        })
    }
    
    /**  Removing file functions  **/
    func removeFiles(files : Array<DJIMediaFile>, completionHandler : @escaping (String?) -> Void){
        let err : String? = self.refreshDroneAndCamera()
        
        if(err != nil){ completionHandler(err!) }
        else{
            self.camera!.mediaManager?.delete(files, withCompletion: {(failedFiles, error) in
                if(error != nil || failedFiles.count != 0){
                    completionHandler("Error during deleting files, details: \(error!)")
                    return
                }
                
                self.refreshMediaList(completionHandler: {(error) in
                    if(error != nil){ completionHandler("Error while reloading photos: \(error!)") }
                    else{ completionHandler(nil) }
                })
            })
        }
    }
    
    func removePreviewFile(completionHandler : @escaping (String?) -> Void){
        if(self.mediaLibPicked == nil) {
            completionHandler("Trying to remove preview file, while not previewing any")
            return
        }
        
        self.removeFiles(files: [self.mediaLibPicked!], completionHandler: {(error) in
            if(error != nil){
                completionHandler(error!)
            } else {
                completionHandler(nil)
            }
        })
    }
    
    /** Saving media functions **/
    func mediaSaved(file : DJIMediaFile) -> Bool {
        if(!savable) { return false }
        let fileUrl = URL(fileURLWithPath: self.libraryURL.relativePath).appendingPathComponent(file.fileName)
        return FileManager.default.fileExists(atPath: fileUrl.relativePath)
    }
    
    func mediaDownloading(file : DJIMediaFile) -> Bool {
        if(!self.mediaDownloading) { return false }
        return self.mediaDownloadList.contains(file)
    }
    
    func prepareAndDownload(selected: Array<DJIMediaFile>) {
        self.mediaDownloadList.removeAll()
        self.mediaDownloaded = 0
        self.stat_dwnBytes = 0
        self.stat_totalBytes = 0
        self.stat_speed = 0
        
        for file in selected {
            self.stat_totalBytes += file.fileSizeInBytes
            if(self.mediaSaved(file: file)){
                if(self.rcProjectManager.mediaUploading){
                    let url = URL(fileURLWithPath: self.libraryURL.relativePath).appendingPathComponent(file.fileName)
                    self.rcProjectManager.sendSingleImage(path: url){ error in
                        if(error != nil){
                            GlobalAlertHelper.shared.createAlert(title: "Upload Error", msg: "Couldn't continue in upload, error: \(error!)")
                        }
                    }
                }
            } else {
                self.mediaDownloadList.append(file)
            }
        }
        
        if(self.mediaDownloadList.count > 0) {
            self.mediaDownloading = true
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)){
                self.saveMediaToDevice(position: 0)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)){
                self.updateTransSpeed(lastBytes: 0)
            }
        }
    }
    
    func updateTransSpeed(lastBytes : Int64){
        let downloaded = self.stat_dwnBytes
        let realBCnt : Int64 = downloaded - lastBytes
        self.stat_speed = Float(realBCnt) / 1000000
        if(self.mediaDownloading) {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)){
                self.updateTransSpeed(lastBytes: downloaded)
            }
        }
    }
    
    func mediaDownloadStop(completionHandler : @escaping (String?) -> Void){
        if(self.mediaDownloading){
            let file = self.mediaDownloadList[self.mediaDownloaded]
            file.stopFetchingFileData(){ (error) in
                if(error != nil) {
                    completionHandler(String(describing:error!))
                } else {
                    self.mediaDownloading = false
                    let fileUrl = URL(fileURLWithPath: self.libraryURL.relativePath).appendingPathComponent(".tmp_"+file.fileName)
                    do { try FileManager.default.removeItem(at: fileUrl) }
                    catch{
                        completionHandler("Error removing non-complete file")
                        return
                    }
                    completionHandler(nil)
                }
            }
        } else {
            completionHandler("Downloading stopped or didn't start")
        }
    }
    
    func saveMediaToDevice(position: Int){
        if(!self.mediaDownloading) { return }
        if(position >= self.mediaDownloadList.count){
            self.mediaDownloading = false
            self.mediaDownloadList.removeAll()
            return
        }
        
        let fileUrl = URL(fileURLWithPath: self.libraryURL.relativePath).appendingPathComponent(".tmp_"+self.mediaDownloadList[position].fileName)
        FileManager.default.createFile(atPath: fileUrl.path, contents: nil)
            
        guard let fileHandle = try? FileHandle(forWritingTo: fileUrl) else {
            self.mediaDownloading = false
            return
        }
        
        self.downloadFullResolutionData(file: self.mediaDownloadList[position], fileHandle: fileHandle){ error in
            if(error != nil) {
                if(self.mediaDownloading){
                    GlobalAlertHelper.shared.createAlert(title: "Downloading Media From Device", msg: "Error message: \(String(describing: error!)).")
                }
                self.mediaDownloading = false
                return
            }
            
            let newFileUrl = URL(fileURLWithPath: self.libraryURL.relativePath).appendingPathComponent(self.mediaDownloadList[position].fileName)
            
            try! fileHandle.close()
            try! FileManager.default.moveItem(at: fileUrl, to: newFileUrl)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10)){
                self.mediaDownloaded += 1
                self.saveMediaToDevice(position: position+1)
            }
        }
    }
    
    func downloadFullResolutionData(file : DJIMediaFile, fileHandle: FileHandle, completionHandler : @escaping (String?) -> Void){
        let err : String? = self.refreshDroneAndCamera()
        if(err != nil){
            completionHandler(String(describing: err!))
            return
        }
        
        file.fetchData(withOffset: 0, update: DispatchQueue.main){ (data,done,error) in
            if(error != nil){
                completionHandler(String(describing: error!))
                return
            }
            fileHandle.write(data!)
            self.stat_dwnBytes += Int64(data!.count)
            if(done) { completionHandler(nil) }
        }
    }
    
    //Got all selected files -> Download And Upload
    func prepareFilesToUpload(selected: [DJIMediaFile]){
        var uploadList : [DJIMediaFile] = []
        for file in selected {
            if(self.isPhoto(file: file) || self.isPano(file: file)){
                uploadList.append(file)
            }
        }
        
        if(uploadList.count > 0){
            self.rcProjectManager.stat_uploaded = 0
            self.rcProjectManager.stat_total = uploadList.count
            self.rcProjectManager.mediaUploading = true
            self.prepareAndDownload(selected: uploadList)
        }
    }
    
    /**  Video functions  **/
    func playVideo(videoMedia: DJIMediaFile, completionHandler : @escaping (String?) -> Void){
        let err : String? = self.refreshDroneAndCamera()
        
        if(err != nil){ completionHandler(err!) }
        else{
            self.camera!.mediaManager!.playVideo(videoMedia, withCompletion: {(error) in
                if(error != nil) {
                    completionHandler(error!.localizedDescription)
                    return
                }
                completionHandler(nil)
            })
        }
    }
    func pauseVideo(completionHandler : @escaping (String?) -> Void){
        let err : String? = self.refreshDroneAndCamera()
        if(err != nil){ completionHandler(err!) }
        else{
            self.camera!.mediaManager!.pause(completion: {(error) in
                if(error != nil){ completionHandler(error!.localizedDescription) }
                else { completionHandler(nil) }
            })
        }
    }
    
    func resumeVideo(completionHandler : @escaping (String?) -> Void){
        let err : String? = self.refreshDroneAndCamera()
        if(err != nil){ completionHandler(err!) }
        else{
            self.camera!.mediaManager!.resume(completion: {(error) in
                if(error != nil){ completionHandler(error!.localizedDescription) }
                else { completionHandler(nil) }
            })
        }
    }
    
    func stopVideo(completionHandler : @escaping (String?) -> Void){
        let err : String? = self.refreshDroneAndCamera()
        
        if(err != nil){ completionHandler(err!) }
        else{
            self.camera!.mediaManager!.stop(completion: {(error) in
                if(error != nil){ completionHandler(error!.localizedDescription) }
                else { completionHandler(nil) }
            })
        }
    }
    
    func changeVideoPreviewTime(time : Float, completionHandler : @escaping (String?) -> Void){
        let err : String? = self.refreshDroneAndCamera()
        
        if(err != nil){ completionHandler(err!) }
        else{
            self.changingVideoTime = true
            self.camera!.mediaManager!.move(toPosition: time, withCompletion: {(error) in
                if(error != nil){ completionHandler(error!.localizedDescription) }
                else {
                    if(!self.mediaPreviewVideoPlaying){
                        self.pauseVideo(){(error) in
                            if(error != nil) { completionHandler(error!) }
                            else {
                                completionHandler(nil)
                                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                                    self.changingVideoTime = false
                                }
                            }
                        }
                    }
                    else {
                        completionHandler(nil)
                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                            self.changingVideoTime = false
                        }
                    }
                }
            })
        }
    }
    
    /**  Helper functions  **/
    func isVideo(file: DJIMediaFile) -> Bool{
        if(file.mediaType == DJIMediaType.MOV || file.mediaType == DJIMediaType.MP4) { return true }
        return false
    }
    
    func isPhoto(file: DJIMediaFile) -> Bool{
        if(file.mediaType == DJIMediaType.JPEG || file.mediaType == DJIMediaType.RAWDNG){ return true }
        return false
    }
    
    func isPano(file: DJIMediaFile) -> Bool{
        if(file.mediaType == DJIMediaType.panorama){ return true }
        return false
    }
    
    func manager(_ manager: DJIMediaManager, didUpdate state: DJIMediaVideoPlaybackState) {
        //Update time of preview
        if(self.mediaLibPicked != nil && !self.changingVideoTime){
            if(self.mediaPreviewVideoCTime != Int(state.playingPosition) && !self.mediaPreviewVideoChanging){
                self.mediaPreviewVideoCTime = Int(state.playingPosition)
            }
        }
    }
}
