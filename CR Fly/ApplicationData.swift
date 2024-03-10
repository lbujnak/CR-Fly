import Foundation
import DJISDK

/**
 A central class designed to manage and observe the state of the application's data. `ApplicationData` serves as a container for various data points related to the application's operation, including device connections, media handling states, and configuration settings.
 
 Usage of `@Published` properties ensures that any views observing this class are notified and updated automatically when these properties change, facilitating a reactive UI that responds to data changes in real time.
 */
public class ApplicationData : ObservableObject {
    
    //TODO: poznamky k jednotlivym premennym?
    
    //MARK: DJI Data
    @Published var djiDevConn = false
    @Published var djiDevice: DJIBaseProduct? = nil
    @Published var droneAlbumPreviewController: DroneAlbumPreviewController? = nil
    
    //MARK: General Album Data
    @Published var mediaDownloadState: MediaDownloadState? = nil
    @Published var mediaUploadState: MediaUploadState? = nil
    
    //MARK: RC Data
    @Published var rcNodeConn = false
    @Published var rcNodeConnLost = false
    @Published var rcNodeIP = "192.168.10.15"
    @Published var rcAuthTkn = "674746F1-C361-413B-B427-BD769E7BE96E" // "383F0345-9E6E-461F-907F-534337987967"
    @Published var rcProjectName: String? = nil
    @Published var rcProjectLoaded: Bool = false
    @Published var rcProjectChanging: Bool = false
}
