import SwiftUI

/**
 `DroneFPVView` is a SwiftUI view that renders the First Person View (FPV) of a DJI drone's camera. It uses a UIKit `UIViewController` wrapped in a `UIViewControllerRepresentable` to integrate DJI's default FPV layout provided by their SDK.
 
 The view handles user interactions and updates the UI accordingly. It also manages the visibility of the FPV interface, initiating necessary drone control commands when the view appears or disappears within the UI.
 
 - Important: This view should be used within a context where the DJI SDK is properly configured and the drone is connected.
 - Note: The view invokes commands on the drone controller when appearing or disappearing, to manage the drone's operational state appropriately.
 */
struct DroneFPVView: AppearableView {
    /// Reference to the `ViewController` responsible for managing navigation, presentation of different views within the application and displaying errors.
    private let viewController = CRFly.shared.viewController
    
    /// Reference to an instance of `DJIDroneController` that facilitates communication and control of the DJI drone.
    private let droneController = CRFly.shared.droneController as! DJIDroneController
    
    /// Called when the object becomes visible within the user interface.
    public func appear() {
        self.droneController.pushCommand(command: ExitDroneAlbum())
    }
    
    /// Called when the object is no longer visible within the user interface.
    public func disappear() { }
    
    /// The body of the `DroneFPVView`, containing the visual layout of the FPV interface. It overlays a custom back button on top of the default DJI FPV layout provided by the SDK, allowing users to navigate back to previous views.
    var body: some View {
        ZStack {
            DefaultFPVLayoutStoryboard().edgesIgnoringSafeArea(.all)
            VStack {
                HStack {
                    Button("←") {
                        self.viewController.displayPreviousView()
                    }.foregroundColor(.white).padding([.horizontal], -10).padding([.top], 40).font(.largeTitle)
                    Spacer()
                }
                Spacer()
            }
        }
    }
    
    /// `DefaultFPVLayoutStoryboard` is a `UIViewControllerRepresentable` that wraps a UIViewController from a storyboard. This class specifically loads the "DefaultFPVView" view controller from the storyboard, allowing it to be used within SwiftUI.
    struct DefaultFPVLayoutStoryboard: UIViewControllerRepresentable {
        func makeUIViewController(context _: Context) -> UIViewController {
            let storyboard = UIStoryboard(name: "DefaultFPVView", bundle: Bundle.main)
            let controller = storyboard.instantiateViewController(identifier: "DefaultFPVView")
            return controller
        }
        
        func updateUIViewController(_: UIViewController, context _: Context) {}
    }
}
