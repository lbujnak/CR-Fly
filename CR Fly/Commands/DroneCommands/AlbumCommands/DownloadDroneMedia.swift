import SwiftUI
import DJISDK

class DownloadDroneMedia: Command {
    var files : [DJIMediaFile]
    var canceled: Bool = false
    
    private var appData = CRFly.shared.appData

    init(files: [DJIMediaFile]) {
        self.files = files
    }
    
    func execute(completion: @escaping () -> Void) {
        if(!self.appData.djiDevConn){ return }
        
        if(self.appData.mediaDownloadState != nil) {
            CRFly.shared.viewController.showSimpleAlert(title: "Error While Downloading Media", msg: Text("Unexpected Error. Download of full-resolution media is already in progress."))
            completion()
            return
        }
        
        var totalBytes: Int64 = 0
        var downloadList: [DJIMediaFile] = []
        
        for file in self.files {
            if(!CRFly.shared.savedAlbumController.isMediaSaved(file: file)){
                totalBytes += file.fileSizeInBytes
                downloadList.append(file)
            }
        }
                
        if(downloadList.count > 0) {
            DispatchQueue.main.asyncAfter(deadline: .now()){
                self.saveMediaToDevice()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)){
                CRFly.shared.updateDroneDownloadSpeed(lastBytesCnt: 0)
            }
            
            CRFly.shared.appData.mediaDownloadState = MediaDownloadState(totalMedia: downloadList.count, totalBytes: totalBytes, downloadedMedia: 0, downloadedBytes: 0, downloadSpeed: 0, downloadList: self.files)
        }
        completion()
    }
    
    func saveMediaToDevice(){
        if(self.appData.mediaDownloadState == nil) { return }
        if(self.appData.mediaDownloadState!.downloadList.isEmpty){
            self.appData.mediaDownloadState = nil
            return
        }
        
        let file = self.appData.mediaDownloadState!.downloadList.first!
        
        let fileUrl = URL(fileURLWithPath: CRFly.shared.savedAlbumController.libraryURL.relativePath).appendingPathComponent(".dwnldTmp_"+file.fileName)
        FileManager.default.createFile(atPath: fileUrl.path, contents: nil)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd kk:mm:ss"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let attributes: [FileAttributeKey: Date] = [.creationDate: dateFormatter.date(from: String(file.timeCreated))!]
        try? FileManager.default.setAttributes(attributes, ofItemAtPath: fileUrl.path)
        
        guard let fileHandle = try? FileHandle(forWritingTo: fileUrl) else {
            self.appData.mediaDownloadState = nil
            CRFly.shared.viewController.showSimpleAlert(title: "Error While Downloading Media", msg: Text("Handle to tmp file couldn't be fetched. Stoping download..."))
            return
        }
        
        file.fetchData(withOffset: 0, update: DispatchQueue.main) { (data,done,error) in
            if(self.canceled){ return }
            
            if(error != nil && !self.canceled){
                CRFly.shared.viewController.showSimpleAlert(title: "Error While Downloading Media", msg: Text("\(String(describing: error!)). Stoping download..."))
                self.appData.mediaDownloadState = nil
                try? FileManager.default.removeItem(atPath: fileUrl.path)
                return
            }
            
            if(self.appData.mediaDownloadState == nil && !self.canceled){
                self.canceled = true
                try? FileManager.default.removeItem(atPath: fileUrl.path)
                file.stopFetchingFileData()
                return
            }
            
            fileHandle.write(data!)
            
            self.appData.mediaDownloadState?.downloadedBytes += Int64(data!.count)
            
            if(done) {
                let newFileUrl = URL(fileURLWithPath: CRFly.shared.savedAlbumController.libraryURL.relativePath).appendingPathComponent(file.fileName)
                do {
                    try fileHandle.close()
                    try FileManager.default.moveItem(at: fileUrl, to: newFileUrl)
                    
                } catch {
                    self.appData.mediaDownloadState = nil
                    CRFly.shared.viewController.showSimpleAlert(title: "Error While Downloading Media", msg: Text("The file handler was unable to close, or the file renaming failed."))
                    return
                }
                
                CRFly.shared.savedAlbumController.addToAlbum(file: newFileUrl)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10)){
                    self.appData.mediaDownloadState!.downloadedMedia += 1
                    self.appData.mediaDownloadState!.downloadList.removeFirst()
                    self.saveMediaToDevice()
                }
            }
        }
    }
}

