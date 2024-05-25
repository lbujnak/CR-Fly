import SwiftUI

/// `ViewController` manages the navigation and presentation of different views within the application. It holds and manages a collection of views associated with specific `ViewType` identifiers, enabling dynamic switching and updating of the UI based on user interactions or application logic. Additionally, it handles error presentations through alert dialogs, facilitating centralized error management and user notification.
public class ViewController: NSObject, ObservableObject {
    /// `ViewType` defines the different types of views that can be managed within the application's navigation system. It facilitates the dynamic handling of various user interfaces by associating each view type with a specific view component. This enumeration is used by `ViewController` to manage and render the appropriate views based on user actions or application flow.
    public enum ViewType: Int {
        /// Represents a state where no view is currently active. Used as a default state.
        case empty
        
        /// Represents the primary or home view of the application.
        case mainView
        
        /// Associated with displaying albums, typically containing media like photos or videos.
        case albumView
        
        /// Used for displaying live video-stream from drone's camera and controlling drone.
        case droneFPVView
        
        /// Used for rendering and interacting with 3D scenes or environments.
        case sceneView
        
        /// Pertains to views that handle scanning functionalities, often using camera input.
        case scannerView
        
        ///  A flexible option intended for custom views that do not fit the predefined categories.
        case custom
    }
    
    /// Stores errors to be presented as alerts.
    @Published var alertErrors: [(String, Text, [(label: String, action: () -> Void)])] = []
    
    /// A boolean flag controlling the visibility of the alert dialog.
    @Published var showAlertError: Bool = false
    
    /// The currently displayed view and its type, allowing dynamic composition.
    @Published var currentView: (ViewType, any AppearableView) = (ViewType.empty, EmptyView())
    
    /// History stack of previously displayed views for navigation.
    private var previousViews: [(ViewType, any AppearableView)] = []
    
    /// Mapping of `ViewType` identifiers to their views.
    private var viewMap: [ViewType: any AppearableView] = [:]
    
    /// Registers a view for a specified `ViewType`.
    public func addView(type: ViewType, view: any AppearableView) {
        self.viewMap[type] = view
    }
    
    /// Returns the `AppWrapperView`, rendering the currently active view.
    public func getView() -> some View {
        AppWrapperView(viewController: self)
    }
    
    /// Identifies the type of the currently displayed view.
    public func getViewType() -> ViewType {
        self.currentView.0
    }
    
    /// Displays a view associated with a specified `ViewType` that was previously added using `addView()`.
    /// - Warning: This method must be called from the main (UI) thread. If you are not on the main thread, use `DispatchQueue.main.async`.
    public func displayView(type: ViewType, addPreviousToHistory: Bool) {
        guard let newView = viewMap[type] else {
            self.showSimpleAlert(title: "Application Navigation Error", msg: Text("The requested view could not be found."))
            return
        }
        
        if addPreviousToHistory {
            self.previousViews.append(self.currentView)
        }
        
        self.currentView.1.disappear()
        self.currentView = (type, newView)
        self.currentView.1.appear()
    }
    
    /// Displays a view associated with the specified `ViewType`.
    /// - Warning: This method must be called from the main (UI) thread. If you are not on the main thread, use `DispatchQueue.main.async`.
    public func displayView(view: any AppearableView, type: ViewType, addPreviousToHistory: Bool) {
        if addPreviousToHistory {
            self.previousViews.append(self.currentView)
        }
        
        self.currentView.1.disappear()
        self.currentView = (type, view)
        self.currentView.1.appear()
    }
    
    /// Navigates back to the most recently viewed view.
    /// - Warning: This method must be called from the main (UI) thread. If you are not on the main thread, use `DispatchQueue.main.async`.
    public func displayPreviousView() {
        guard let previous = previousViews.popLast() else {
            self.showSimpleAlert(title: "Application Navigation Error", msg: Text("No previous view available to return to."))
            return
        }
        self.currentView.1.disappear()
        self.currentView = previous
        self.currentView.1.appear()
    }
    
    /// Prepares and queues an alert for display.
    /// - Warning: This method must be called from the main (UI) thread. If you are not on the main thread, use `DispatchQueue.main.async`.
    public func showAlert(title: String, msg: Text, buttons: [(label: String, action: () -> Void)]) {
        self.alertErrors.append((title, msg, buttons))
        if self.alertErrors.count == 1 {
            self.showAlertError = true
        }
    }
    
    /// Shows a simple alert with a "Cancel" button.
    /// - Warning: This method must be called from the main (UI) thread. If you are not on the main thread, use `DispatchQueue.main.async`.
    public func showSimpleAlert(title: String, msg: Text) {
        self.showAlert(
            title: title,
            msg: msg,
            buttons: [(label: "Cancel", action: { })]
        )
    }
    
    /// Clears the current alert from the queue.
    /// - Warning: This method must be called from the main (UI) thread. If you are not on the main thread, use `DispatchQueue.main.async`.
    public func clearAlertError() {
        if !self.alertErrors.isEmpty { self.alertErrors.removeFirst() }
    }
}
