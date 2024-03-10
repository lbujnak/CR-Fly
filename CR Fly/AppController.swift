import SwiftUI
import DJISDK

/**
 `AppController` serves as the main entry point and orchestrator for the SwiftUI application. It leverages the singleton instance of `CRFly` to initialize and manage core components of the application, including drone control, view management, and application data.

 The `AppController` struct conforms to the `App` protocol, defining the application's configuration and its scene (or scenes), which determine the content and lifecycle events of the app.
*/
@main
struct AppController: App {
    @ObservedObject var viewController = CRFly.shared.viewController
    
    init(){
        CRFly.shared.droneController.registerWithSDK()
        CRFly.shared.initViews()
    }
    
    var body: some Scene {
        WindowGroup {
            viewController.getView()
        }
    }
}
