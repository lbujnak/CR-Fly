import Foundation
import DJISDK

class DroneHelper {
    static func filterArrayEmpty(checkFiles: [DJIMediaFile], filter: MediaFilter) -> Bool{
        for file in checkFiles {
            if(self.fileAcceptFilter(file: file, filter: filter)) { return false }
        }
        return true
    }
    
    static func filterMapEmpty(checkFiles: [Date: [DJIMediaFile]], filter: MediaFilter) -> Bool{
        for (date,files) in checkFiles {
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
    
    static func isVideo(file: DJIMediaFile) -> Bool{
        if(file.mediaType == DJIMediaType.MOV || file.mediaType == DJIMediaType.MP4) { return true }
        return false
    }
        
    static func isPhoto(file: DJIMediaFile) -> Bool{
        if(file.mediaType == DJIMediaType.JPEG || file.mediaType == DJIMediaType.RAWDNG){ return true }
        return false
    }
        
    static func isPano(file: DJIMediaFile) -> Bool{
        if(file.mediaType == DJIMediaType.panorama){ return true }
        return false
    }
}
