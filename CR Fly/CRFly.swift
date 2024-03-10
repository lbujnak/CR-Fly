import SwiftUI
import DJISDK

/**
 `CRFly` is a singleton class designed to serve as the central hub for managing the core components of the application, including data storage, view controllers, and various controllers related to drone and album functionalities.
 
 - Methods:
     - `initViews()`: Initializes the views required for the application by registering them with the `viewController` and attempting to display the main view. This method sets up the application's initial state and ensures that the necessary views are available and correctly configured for display.
    - `updateDroneDownloadSpeed` TODO alebo PREMIESTNIT
 
 - Usage Context:
 `CRFly` is utilized within an `AppController` or the main `App` class to coordinate application-wide behaviors, ensuring that there is a single, unified access point for managing key components and data. This approach simplifies interactions between different parts of the application and promotes a modular architecture by centralizing control and state management.

 - Example:
 To initialize the application views and set up the initial view state, `CRFly.shared.initViews()` is called during the application's startup sequence. This ensures that all views are registered and ready for display, and the main view is shown to the user.
*/
public class CRFly: ObservableObject {
    static var shared = CRFly()

    //Data
    @Published var appData = ApplicationData()
    
    //Controllers
    @Published var viewController = ViewController()
    @Published var droneController = DroneController()
    @Published var sceneController = SceneController()
    @Published var droneAlbumController = DroneAlbumController()
    @Published var savedAlbumController = SavedAlbumController()
    
    public func initViews(){
        self.viewController.addView(type: .mainView, view: AnyView(MainView(appData: CRFly.shared.appData)))
        self.viewController.addView(type: .albumView, view: AnyView(AlbumView(appData: CRFly.shared.appData, controller: CRFly.shared.savedAlbumController)))
        self.viewController.addView(type: .sceneView, view: AnyView(MeshWorkspaceView(appData: CRFly.shared.appData)))
        self.viewController.addView(type: .scannerView, view: AnyView(ScannerView()))
        self.viewController.displayView(type: .mainView, addToHistory: false)
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
