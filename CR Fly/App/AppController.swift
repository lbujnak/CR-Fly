import DJISDK
import SwiftUI

/**
 `AppController` functions as the central management hub for the SwiftUI application, orchestrating the initialization and coordination of key components managed by `CRFly`. It conforms to the `App` protocol, setting up the application's main interface and handling significant application lifecycle events.
 
 - Application Lifecycle: Handles major lifecycle events such as the application entering the foreground or background, ensuring that all parts of the application respond correctly to these events.
 - Scene Configuration: Defines the content and behavior of the application's window, integrating the main view controller's view as the root of the interface.
 */
@main
public struct AppController: App {
    /// Reference to the `ViewController` responsible for managing navigation, presentation of different views within the application and displaying errors.
    @ObservedObject private var viewController = CRFly.shared.viewController
    
    /// Registers the application with DJI's SDK to enable drone functionalities. Also calls `initViews()` on `CRFly` to set up initial views and configure the main user interface.
    public init() {
        (CRFly.shared.droneController as! DJIDroneController).registerWithSDK()
        CRFly.shared.initViews()
    }
    
    /// Defines the user interface of the app within a window group, attaching handlers for app lifecycle notifications.
    public var body: some Scene {
        WindowGroup {
            self.viewController.getView()
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    self.willEnterForegroundNotification()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    self.didEnterBackgroundNotification()
                }
        }
    }
    
    /// Called when the app enters the background; manages necessary state preservation and pausing of activities.
    private func didEnterBackgroundNotification() {
        CRFly.shared.droneController.leaveToBackground()
        CRFly.shared.albumDroneController.leaveToBackground()
        CRFly.shared.albumSavedController.leaveToBackground()
        CRFly.shared.sceneController.leaveToBackground()
    }
    
    /// Called when the app returns to the foreground; reinstates activities and states as necessary.
    private func willEnterForegroundNotification() {
        CRFly.shared.droneController.enterFromBackground()
        CRFly.shared.albumDroneController.enterFromBackground()
        CRFly.shared.albumSavedController.enterFromBackground()
        CRFly.shared.sceneController.enterFromBackground()
    }
}
