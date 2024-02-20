import SwiftUI
import DJISDK

class AlbumHelper {
    static func filterMapEmpty(checkFiles: [Date: [DJIMediaFile]], filter: MediaFilter) -> Bool{
        for (_,files) in checkFiles {
            for file in files {
                if(self.fileAcceptFilter(file: file, filter: filter)) { return false }
            }
        }
        return true
    }
    
    static func filterMapEmpty(checkFiles: [Date: [URL]], filter: MediaFilter) -> Bool{
        for (_,files) in checkFiles {
            for file in files {
                if(self.fileAcceptFilter(file: file, filter: filter)) { return false }
            }
        }
        return true
    }
    
    static func fileAcceptFilter(file: DJIMediaFile, filter: MediaFilter) ->Bool{
        switch(filter){
            case .all: return true
            case .photos: return self.isPano(file: file) || self.isPhoto(file: file)
            case .videos: return self.isVideo(file: file)
        }
    }
    
    static func fileAcceptFilter(file: URL, filter: MediaFilter) ->Bool{
        switch(filter){
            case .all: return true
            case .photos: return self.isPhoto(file: file)
            case .videos: return self.isVideo(file: file)
        }
    }
    
    static func isVideo(file: DJIMediaFile) -> Bool{
        if(file.mediaType == DJIMediaType.MOV || file.mediaType == DJIMediaType.MP4) { return true }
        return false
    }
    
    static func isVideo(file: URL) -> Bool{
        let ext = file.pathExtension.lowercased()
        if(ext == "mov" || ext == "mp4") { return true }
        return false
    }
        
    static func isPhoto(file: DJIMediaFile) -> Bool{
        if(file.mediaType == DJIMediaType.JPEG || file.mediaType == DJIMediaType.RAWDNG){ return true }
        return false
    }
    
    static func isPhoto(file: URL) -> Bool{
        let ext = file.pathExtension.lowercased()
        if(ext == "jpg" || ext == "jpeg" || ext == "rawdng") { return true }
        return false
    }
        
    static func isPano(file: DJIMediaFile) -> Bool{
        if(file.mediaType == DJIMediaType.panorama){ return true }
        return false
    }
    
    static func createDwnUpInfo(appData: ApplicationData) -> some View {
        VStack{
            if(appData.mediaDownloadState != nil){
                VStack(spacing: 0){
                    ProgressView(value: Double(appData.mediaDownloadState!.downloadedBytes), total: Double(appData.mediaDownloadState!.totalBytes)).progressViewStyle(.linear).background(Color(red: 0.100, green: 0.100, blue: 0.100)).ignoresSafeArea()
                    
                    HStack(spacing: 10){
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaledToFit().padding([.horizontal],10)
                        
                        let perc = Int(Float(appData.mediaDownloadState!.downloadedBytes) / Float(appData.mediaDownloadState!.totalBytes)*100)
                        Text(String(format: "%d%% Downloading files(%d/%d) %.2fMB/s", perc, appData.mediaDownloadState!.downloadedMedia, appData.mediaDownloadState!.totalMedia, appData.mediaDownloadState!.downloadSpeed)).foregroundColor(.white).font(.caption)
                        
                        Spacer()
                        
                        Image(systemName: "xmark").onTapGesture {
                            /*self.libController.mediaDownloadStop() { (error) in
                             if(error != nil){
                             GlobalAlertHelper.shared.createAlert(title: "Stopping download", msg: "There was a problem stopping download: " + error!)
                             }
                             }*/
                        }.padding([.horizontal],-40).foregroundColor(.white)
                    }.frame(height: 30).ignoresSafeArea().background(Color(red: 0.100, green: 0.100, blue: 0.100))
                }.padding([.vertical],-5)
            }
            
            if(appData.mediaUploadState != nil) {
                /*VStack(spacing: 0){
                    ProgressView(value: Double(self.rcProjectManagement.stat_uploaded), total: Double(self.rcProjectManagement.stat_total)).progressViewStyle(.linear).background(Color(red: 0.100, green: 0.100, blue: 0.100)).ignoresSafeArea()
                    
                    HStack(spacing: 10){
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaledToFit().padding([.horizontal],10)
                        
                        Text("Uploading files to CR \(self.rcProjectManagement.stat_uploaded)/\(self.rcProjectManagement.stat_total), Project name: \(self.rcProjectManagement.currentProject.name)").foregroundColor(.white).font(.caption)
                        
                        Spacer()
                        
                        Image(systemName: "xmark").onTapGesture {
                            self.rcProjectManagement.mediaUploading = false
                        }.padding([.horizontal],-40).foregroundColor(.white)
                    }.frame(height: 30).ignoresSafeArea().background(Color(red: 0.100, green: 0.100, blue: 0.100))
                }.padding([.vertical],-5)*/
            }
        }
    }
    
    static func selectedFilesInfo(files : [DJIMediaFile]) -> Text {
        var total: Int64 = 0
        for obj in files{ total += obj.fileSizeInBytes }
        return self.generateSelectStatus(totalBytes: Double(total/1000000), fileCount: files.count)
    }
    
    static func selectedFilesInfo(files : [URL]) -> Text {
        var total: Int64 = 0
        for file in files {
            do{
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: file.path)
                if let fileSize = fileAttributes[.size] as? NSNumber {
                    total += fileSize.int64Value
                }
            } catch { continue }
        }
        return self.generateSelectStatus(totalBytes: Double(total/1000000), fileCount: files.count)
    }
    
    static func generateSelectStatus(totalBytes: Double, fileCount: Int) -> Text {
        if(totalBytes <= 1000) {
            return Text("\(fileCount) file(s) selected (\(String(format: "%.2f", totalBytes)) MB)")
        } else {
            return Text("\(fileCount) file(s) selected (\(String(format: "%.2f", totalBytes/1000)) GB)")
        }
    }
    
    static func secondsToVideoTime(seconds : Int) -> VideoTime {
        let hours = seconds/3600
        let minutes = (seconds - hours*3600)/60
        let sec = (seconds - hours*3600 - minutes*60)
        return VideoTime(hours: hours, minutes: minutes, seconds: sec)
    }
}
