import SwiftUI

/**
 `AlbumDroneVideoPlayback` is a SwiftUI view that renders the DJI drone's camera video playback stream. It uses a UIKit `UIViewController` wrapped in a `UIViewControllerRepresentable` to integrate with `FPVView`which is a customized version of DJI's default FPV layout provided by their SDK.
 
 The view handles user interactions and updates the UI accordingly. It also manages the visibility of the FPV interface, initiating necessary drone control commands when the view appears or disappears within the UI.
 
 - Important: This view should be used within a context where the DJI SDK is properly configured and the drone is connected.
 - Note: The view invokes commands on the drone controller when appearing or disappearing, to manage the drone's operational state appropriately.
 */
public struct AlbumDroneVideoPlayback: AppearableView {
    public func appear() {}
    public func disappear() {}
    
    public var body: some View {
        DJIFPVLayoutStoryboard().edgesIgnoringSafeArea(.all)
    }
    
    /// `DJIFPVLayoutStoryboard` is a `UIViewControllerRepresentable` that wraps a UIViewController from a storyboard. This class specifically loads the "FPVView" view controller from the storyboard, allowing it to be used within SwiftUI.
    public struct DJIFPVLayoutStoryboard: UIViewControllerRepresentable {
        public func makeUIViewController(context _: Context) -> UIViewController {
            let storyboard = UIStoryboard(name: "FPVView", bundle: Bundle.main)
            let controller = storyboard.instantiateViewController(identifier: "FPVView")
            return controller
        }
        
        public func updateUIViewController(_: UIViewController, context _: Context) {}
    }
}
