import Foundation
import DJISDK

public class CRFly: ObservableObject {
    static var shared = CRFly()

    //Data
    @Published var appData = ApplicationData()
    
    //Controllers
    @Published var viewController = ViewController()
    @Published var droneController = DroneController()
    
    @Published var libraryURL : URL = URL(filePath: NSHomeDirectory())
    init() {
        self.loadSavedMedia()
    }
    
    private func loadSavedMedia(){
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
        self.appData.mediaSavable = true
        
        do {
            let fileManager = FileManager.default
            let fileURLs = try FileManager.default.contentsOfDirectory(at: self.libraryURL, includingPropertiesForKeys: nil)
            
            for fileURL in fileURLs {
                let filePath = fileURL.path
                let attributes = try fileManager.attributesOfItem(atPath: filePath)
                if let creationDate = attributes[.creationDate] as? Date {
                    let fileExtension = fileURL.pathExtension.lowercased()
                    switch fileExtension {
                        case "jpg","jpeg","rawdng", "mov", "mp4":
                            let fileDate = SimpleDateFormatter().date(from: String(creationDate.description.prefix(10)))!
                            
                            if let _ = self.appData.mediaSavedAlbum[fileDate] {
                                self.appData.mediaSavedAlbum[fileDate]!.append(fileURL)
                            } else {
                                self.appData.mediaSavedAlbum[fileDate] = [fileURL]
                            }
                        default: continue
                    }
                }
            }
        } catch {
            print("Error loading files from Saved Media directory: \(error)")
        }
    }
    
    public func isMediaSaved(file: DJIMediaFile) -> Bool {
        let fileDateString = String(file.timeCreated.prefix(10))
        let fileDate = SimpleDateFormatter().date(from: fileDateString)!
        
        if let urls = self.appData.mediaSavedAlbum[fileDate] {
            return urls.contains { $0.lastPathComponent == file.fileName }
        }
        return false
    }
    
    public func updateDroneDownloadSpeed(lastBytesCnt: Int64) {
        if(self.appData.mediaDownloadState != nil) {
            let downloaded = self.appData.mediaDownloadState!.downloadedBytes
            let realByteCnt : Int64 = downloaded - lastBytesCnt
            let newSpeed = Float(realByteCnt) / 1000000
            
            self.appData.mediaDownloadState!.downloadSpeed = newSpeed
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)){
                self.updateDroneDownloadSpeed(lastBytesCnt: downloaded)
            }
        }
    }
}
