import Foundation
import DJISDK

public class ApplicationData : ObservableObject {
    
    //MARK: MainView Data
    @Published var mediaSavable: Bool = false
    @Published var mediaThumbnailFetching: Bool = false
    @Published var mediaDownloadState: MediaDownloadState? = nil
    @Published var mediaUploadState: MediaUploadState? = nil
    
    //MARK: DJI Data
    @Published var djiDevConn = false
    @Published var djiDevice: DJIBaseProduct? = nil
    
    @Published var djiAlbumMedia: [Date: [DJIMediaFile]] = [:]
    @Published var djiAlbumMediaSaved: [Date : [URL]] = [:]
    
    //MARK: RC Data
    @Published var rcNodeConn = false
    @Published var rcNodeIP = "192.168.10.15"
    @Published var rcAuthTkn = "674746F1-C361-413B-B427-BD769E7BE96E" // "383F0345-9E6E-461F-907F-534337987967"
    @Published var projectName: String? = nil
}
