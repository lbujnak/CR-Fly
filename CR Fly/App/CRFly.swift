import DJISDK
import SwiftUI

/// `CRFly` is a singleton class designed to serve as the central hub for managing the core components of the application, including data storage, view controllers, and various controllers related to drone and album functionalities.
public class CRFly {
    /// Access to shared instance of `CRFly`
    public static var shared = CRFly()
    
    /// Reference to the `ViewController` responsible for managing navigation, presentation of different views within the application and displaying errors.
    public let viewController: ViewController
    
    /// Reference to an instance of `DroneController` that facilitates communication and control of the drone.
    public let droneController: DroneController
    
    /// Reference to an instance of `SceneController` that manages broader scene-related operations.
    public let sceneController: SceneController
    
    /// Reference to an instance of `AlbumSavedController` that manages the overall album of saved media.
    public let albumSavedController: AlbumSavedController
    
    /// Reference to an instance of `AlbumDroneController` that manages the overall album of drone's media.
    public let albumDroneController: AlbumDroneController
    
    /// Reference to observable object `SharedData` which contains common data used across different components of the application.
    public let sharedData = SharedData()
    
    /// Initializes all controllers with dependencies injected as needed. This setup promotes a decoupled architecture where each controller can operate independently while still contributing to a unified application behavior. Ensures that each component is ready to perform its role by the time the application starts, setting a solid foundation for the app's runtime operations.
    init() {
        let viewController = ViewController()
        let sceneController = RCNodeController(viewController: viewController)
        let albumSavedController = AlbumSavedController(viewController: viewController, sceneController: sceneController)
        let droneController = DJIDroneController(viewController: viewController, sceneController: sceneController, albumSavedController: albumSavedController)
        
        self.viewController = viewController
        self.droneController = droneController
        self.sceneController = sceneController
        self.albumSavedController = albumSavedController
        self.albumDroneController = AlbumDroneController(viewController: viewController, droneController: droneController, sceneController: sceneController, albumSavedController: albumSavedController)
    }
    
    /// Registers all necessary views with the `viewController` and sets the initial view state for the application. This method is crucial for preparing the application's user interface upon launch.
    public func initViews() {
        self.viewController.addView(type: .mainView, view: MainView(viewController: self.viewController, droneController: self.droneController, sharedData: self.sharedData))
        self.viewController.addView(type: .albumView, view: AlbumView(albumMode: .saved, viewController: self.viewController, sceneData: self.sceneController.sceneData, droneData: self.droneController.droneData, albumSavedController: self.albumSavedController, albumDroneController: self.albumDroneController))
        self.viewController.addView(type: .droneFPVView, view: DroneFPVView())
        self.viewController.addView(type: .sceneView, view: MeshWorkspaceView(viewController: self.viewController, sceneController: self.sceneController))
        self.viewController.addView(type: .scannerView, view: ScannerView(viewController: self.viewController, sceneController: self.sceneController, sharedData: self.sharedData))
        
        self.viewController.displayView(type: .mainView, addPreviousToHistory: false)
    }
    
    /// Method allows changing the album mode dynamically by re-adding the AlbumView with the new mode.
    public func changeAlbumMode(albumMode: AlbumView.AlbumMode) {
        self.viewController.addView(type: .albumView, view: AlbumView(albumMode: albumMode, viewController: self.viewController, sceneData: self.sceneController.sceneData, droneData: self.droneController.droneData, albumSavedController: self.albumSavedController, albumDroneController: self.albumDroneController))
    }
}
