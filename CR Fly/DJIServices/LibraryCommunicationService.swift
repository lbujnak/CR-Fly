import Foundation
import SwiftUI
import DJISDK

class LibraryCommunicationService : NSObject, DJIMediaManagerDelegate, ObservableObject {
    
    @Published var mediaFilter = 0 //0 - All, 1 - Photos, 2 - Videos
    @Published var mediaList : [DJIMediaFile] = []
    @Published var mediaSections : [[DJIMediaFile]] = []
    @Published var mediaFetched = false
    @Published var mediaLibPicked : DJIMediaFile? = nil
    @Published var mediaPreviewReady = false
    @Published var mediaPreviewVideoPlaying = false
    @Published var mediaPreviewVideoCTime : Int = 0
    @Published var mediaPreviewVideoChanging : Bool = false
    
    private var drone : DJIBaseProduct? = nil
    private var camera : DJICamera? = nil
    private var changingVideoTime : Bool = false
    
    private func refreshDroneAndCamera() -> String? {
        self.drone = DJISDKManager.product()
        if(self.drone == nil){ return "Product is connected, but DJISDKManager.product() is nil" }
        
        self.camera = drone!.camera
        if(self.camera == nil){ return "Unable to detect camera" }
        
        if(!camera!.isMediaDownloadModeSupported()){ return "Product does not support media download mode" }
        
        self.camera!.mediaManager!.delegate = self
        return nil
    }
    
    func startPlaybackMode(downloadPreview: Bool, completionHandler: @escaping (String?) -> Void){
        
        let err : String? = self.refreshDroneAndCamera()
        if(err != nil){
            completionHandler(err!)
            return
        }
        
        if(camera!.displayName == DJICameraDisplayNameZenmuseP1 || camera!.displayName == DJICameraDisplayNameMavicAir2Camera){
            self.camera!.enterPlayback(completion: {(error) in
                if (error != nil) {
                    completionHandler(error!.localizedDescription)
                    return
                }
            })
        }
        else{
            self.camera!.setMode(.mediaDownload, withCompletion: {(error) in
                if(error != nil)
                {
                    completionHandler(error!.localizedDescription)
                    return
                }
            })
        }
            
        let manager = camera!.mediaManager!
        manager.refreshFileList(of: DJICameraStorageLocation.sdCard, withCompletion: { (error) in
            if(error != nil){
                completionHandler("refresh error state: \(error!.localizedDescription)")
                return
            }
            
            let files : [DJIMediaFile] = manager.sdCardFileListSnapshot() ?? []
                        
            if(!self.mediaList.elementsEqual(files)){
                self.mediaList.removeAll()
                self.mediaSections.removeAll()
                self.mediaPreviewReady = false
                            
                var sections = 0
                for i in 0..<files.count{
                    if(self.mediaList.last?.timeCreated.prefix(10) != files[i].timeCreated.prefix(10)){
                        var newSection : [DJIMediaFile] = []
                        newSection.append(files[i])
                                    
                        self.mediaSections.append(newSection)
                        sections += 1
                    }
                    self.mediaList.append(files[i])
                    self.mediaSections[sections-1].append(files[i])
                }
                            
                if(self.mediaList.count > 0 && downloadPreview){
                    self.downloadThumbnail(index: 0, retries: 0)
                }
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
                completionHandler("While exiting playbackMode catched error: \(error!.localizedDescription)")
                return
            }
                
            completionHandler(nil)
        })
    }
    
    private func downloadThumbnail(index: Int, retries: Int){
        if(index >= self.mediaList.count){
            self.mediaFetched = true
        }
        else{
            self.mediaList[index].fetchThumbnail(completion: { (error) in
                if(error != nil ) {
                    print("dwnld error: \(error!)")
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
                if(ViewHelper.shared.libMode) {
                    self.downloadThumbnail(index: self.mediaList.index(after: index), retries: retries)
                }
            })
        }
    }
    
    func removeFiles(files : Set<DJIMediaFile>, completionHandler : @escaping (String?) -> Void){
        let err : String? = self.refreshDroneAndCamera()
        var remFileList : [DJIMediaFile] = []
        
        if(err != nil){ completionHandler(err!) }
        else{
            for file in files{ remFileList.append(file) }
            
            self.camera!.mediaManager?.delete(remFileList, withCompletion: {(failedFiles, error) in
                if(error != nil || failedFiles.count != 0){
                    completionHandler("Error during deleting files, details: \(error!)")
                    return
                }
                
                self.startPlaybackMode(downloadPreview: false, completionHandler: {(error) in
                    if(error != nil){ completionHandler("Error while reloading photos: \(error!)") }
                    else{ completionHandler(nil) }
                })
            })
        }
    }
    
    func removePreviewFile(completionHandler : @escaping (String?) -> Void){
        let err : String? = self.refreshDroneAndCamera()
        var files : Set<DJIMediaFile> = []
        
        if(err != nil){
            completionHandler(err!)
            return
        }
        
        if(self.mediaLibPicked == nil) {
            completionHandler("Trying to remove preview file, while not previewing any")
            return
        }
        
        files.insert(self.mediaLibPicked!)
        
        self.removeFiles(files: files, completionHandler: {(error) in
            completionHandler(error!)
        })
    }
    
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
    
    func manager(_ manager: DJIMediaManager, didUpdate state: DJIMediaVideoPlaybackState) {
        //Update time of preview
        if(self.mediaLibPicked != nil && !self.changingVideoTime){
            if(self.mediaPreviewVideoCTime != Int(state.playingPosition) && !self.mediaPreviewVideoChanging){
                self.mediaPreviewVideoCTime = Int(state.playingPosition)
            }
            
            //FIXED ?
            //Replaying video after end, to be ready for resume
            /*if(state.playbackStatus == DJIMediaVideoPlaybackStatus.stopped && self.globalData.mediaPreviewVideoPlaying && !self.globalData.mediaPreviewVideoChanging){
                self.globalData.mediaPreviewReady = false
                self.globalData.mediaPreviewVideoPlaying = false
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    self.prepareVideoPreview(file: self.globalData.mediaLibPicked!)
                }
            }*/
        }
    }
}
