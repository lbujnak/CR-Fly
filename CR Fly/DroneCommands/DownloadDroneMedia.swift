import SwiftUI
import DJISDK

class DownloadDroneMedia: DroneCommand {
    private var selectedItems : [DJIMediaFile]
    private var appData = CRFly.shared.appData

    init(selectedItems: Array<DJIMediaFile>) {
        self.selectedItems = selectedItems
    }
    
    func execute(completion: @escaping () -> Void) {
        if(self.appData.mediaDownloadState != nil) {
            CRFly.shared.viewController.showSimpleAlert(title: "Error While Downloading Media", msg: Text("Unexpected Error. Download of full-resolution media is already in progress."))
        }
        
        var totalBytes: Int64 = 0
        var downloadList: [DJIMediaFile] = []
        
        for file in self.selectedItems {
            if(!CRFly.shared.isMediaSaved(file: file)){
                totalBytes += file.fileSizeInBytes
                downloadList.append(file)
            }
        }
                
        if(downloadList.count > 0) {
            DispatchQueue.main.asyncAfter(deadline: .now()){
                self.saveMediaToDevice(downloadList: downloadList, position: 0)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)){
                CRFly.shared.updateDroneDownloadSpeed(lastBytesCnt: 0)
            }
            
            CRFly.shared.appData.mediaDownloadState = MediaDownloadState(totalMedia: downloadList.count, totalBytes: totalBytes, downloadedMedia: 0, downloadedBytes: 0, downloadSpeed: 0)
        }
    }
    
    func saveMediaToDevice(downloadList: [DJIMediaFile], position: Int){
        if(self.appData.mediaDownloadState == nil) { return }
        if(position >= downloadList.count){
            self.appData.mediaDownloadState = nil
            return
        }
        
        let fileUrl = URL(fileURLWithPath: CRFly.shared.libraryURL.relativePath).appendingPathComponent(".tmp_"+downloadList[position].fileName)
        FileManager.default.createFile(atPath: fileUrl.path, contents: nil)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd kk:mm:ss"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let attributes: [FileAttributeKey: Date] = [.creationDate: dateFormatter.date(from: String(downloadList[position].timeCreated))!]
        try? FileManager.default.setAttributes(attributes, ofItemAtPath: fileUrl.path)
        
        guard let fileHandle = try? FileHandle(forWritingTo: fileUrl) else {
            self.appData.mediaDownloadState = nil
            CRFly.shared.viewController.showSimpleAlert(title: "Error While Downloading Media", msg: Text("Handle to .tmp file couldn't be fetched. Stoping download..."))
            return
        }
        
        downloadList[position].fetchData(withOffset: 0, update: DispatchQueue.main){ (data,done,error) in
            if(error != nil){
                CRFly.shared.viewController.showSimpleAlert(title: "Error While Downloading Media", msg: Text("\(String(describing: error!)). Stoping download..."))
                self.appData.mediaDownloadState = nil
                return
            }
            fileHandle.write(data!)
            self.appData.mediaDownloadState?.downloadedBytes += Int64(data!.count)
            if(done) {
                let newFileUrl = URL(fileURLWithPath: CRFly.shared.libraryURL.relativePath).appendingPathComponent(downloadList[position].fileName)
                do {
                    try fileHandle.close()
                    try FileManager.default.moveItem(at: fileUrl, to: newFileUrl)
                    
                } catch {
                    self.appData.mediaDownloadState = nil
                    CRFly.shared.viewController.showSimpleAlert(title: "Error While Downloading Media", msg: Text("The file handler was unable to close, or the file renaming failed."))
                    return
                }
                
                let dateString = String(downloadList[position].timeCreated.prefix(10))
                let fileDate = SimpleDateFormatter().date(from: dateString)!
                
                if let _ = self.appData.djiAlbumMediaSaved[fileDate] {
                    self.appData.djiAlbumMediaSaved[fileDate]!.append(newFileUrl)
                } else {
                    self.appData.djiAlbumMediaSaved[fileDate] = [newFileUrl]
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10)){
                    self.appData.mediaDownloadState!.downloadedMedia += 1
                    self.saveMediaToDevice(downloadList: downloadList, position: position+1)
                }
            }
        }
    }
}
