import SwiftUI

public enum ViewType {
    case empty
    case mainView
    case albumView
    case albumMediaPreview
    case sceneView
    case scannerView
}

/**
 `ViewController` is a central class designed to manage the navigation and presentation of different views within the application.

 - Properties:
     - `alertErrors`: Stores a list of errors to be presented as alerts.
     - `showAlertError`: A Boolean flag that controls the visibility of the alert dialog.
     - `currentView`: The currently displayed view, represented as a tuple of `ViewType` and `AnyView`.
     - `previousViews`: A history stack of previously displayed views. This enables navigation back to previous states.
     - `viewMap`: A dictionary mapping `ViewType` identifiers to their corresponding `AnyView` objects.

  - Methods:
     - `addView(type:view:)`: Registers a view for a specified `ViewType`, allowing it to be displayed when requested by this type.
     - `getView()`: Returns the `CurrentView`, a SwiftUI view that renders the currently active view based on `currentView`.
     - `getViewType()`: Returns the type of the currently displayed view.
     - `displayView(type:)`: Attempts to display a view associated with a specified `ViewType`. It updates `currentView` and the history stack `previousViews`.
     - `displayView(view:type:)`: Displays a given view and updates the navigation history similar to `displayView(type:)`, but allows specifying the view directly.
     - `showAlert(title:msg:buttons:)`: Prepares an alert with a title, message, and buttons for display. Queues the alert for presentation.
     - `showSimpleAlert(title:msg:)`: A convenience method for showing an alert with a single "Cancel" button.
     - `clearAlertError()`: Clears the current alert from the queue and prepares the next alert for display if available.

 This class manages a collection of views associated with specific `ViewType` identifiers, enabling dynamic switching and updating of the application's UI based on user interaction or application logic. It also handles error presentation through alert dialogs, facilitating centralized error management and user notification.
*/

public class ViewController: NSObject, ObservableObject {
    
    /** Stores errors to be presented as alerts. */
    @Published var alertErrors: [(String, Text, [(label: String, action: () -> Void)])] = []
    
    /** Controls the visibility of the alert dialog. When `true`, an alert dialog is presented to the user. */
    @Published var showAlertError: Bool = false
    
    /** The currently displayed view and its associated type. The `ViewType` is used to identify the view,
     and `AnyView` allows for dynamic view composition. */
    @Published var currentView: (ViewType, AnyView) = (ViewType.empty, AnyView(EmptyView()))
    
    /** A history of previously displayed views, enabling navigation back to earlier views. */
    @Published var previousViews: [(ViewType, AnyView)] = []
    
    /** Maps `ViewType` identifiers to their corresponding `AnyView` objects, facilitating
     the dynamic retrieval and display of views based on their type. */
    private var viewMap: [ViewType : AnyView] = [:]
    
    /** Registers a view for a specified `ViewType`, allowing it to be displayed when requested by this type.
    - Parameters:
         - type: The `ViewType` identifier for the view.
         - view: The view to be registered as `AnyView`. */
    public func addView(type: ViewType, view: AnyView) {
        self.viewMap[type] = view
    }
    
    /** Returns the `CurrentView`, a SwiftUI view that renders the currently active view based on `currentView`. */
    public func getView() -> some View {
        CurrentView(controller: self)
    }
    
    /** Returns the type of the currently displayed view. */
    public func getViewType() -> ViewType {
        return self.currentView.0
    }
    
    /**
     Attempts to display a view associated with the specified `ViewType` by updating the `currentView` with the view identified by the `type` key in the `viewMap`. This action facilitates navigation within the application by moving forward to the next state represented by the requested view. The view must be pre-registered in `viewMap`.
     
     If `viewMap` does not contain an `AnyView` identified by `type`, the method will display an alert informing the user of the unsuccessful navigation attempt.
     
     - Parameter type: The `ViewType` identifier used to determine the specific view to be opened and displayed.
     - Parameter addToHistory: A Boolean flag indicating whether the currently displayed view should be stored in the navigation history before updating to the new view. If `true`, the current view is added to the `previousViews` stack, allowing for backward navigation.
    */
    public func displayView(type: ViewType, addToHistory: Bool) {
        guard let newView = self.viewMap[type] else {
            self.showSimpleAlert(title: "Application Navigation Error", msg: Text("The requested view could not be found."))
            return
        }
        
        DispatchQueue.main.async {
            if(addToHistory){
                self.previousViews.append(self.currentView)
            }
            self.currentView = (type, newView)
        }
    }
    
    /**
     Displays a view associated with the specified `ViewType`.
     - Parameter view: The `AnyView` object representing the view that will be displayed.
     - Parameter type: The `ViewType` identifier used to categorize or identify the type of the view being displayed.
     - Parameter addToHistory: A Boolean flag indicating whether the currently displayed view should be stored in the navigation history before updating to the new view. If `true`, the current view is added to the `previousViews` stack, allowing for backward navigation.

     This method dynamically updates the `currentView` to the provided `view` and assigns it the corresponding `type`. This action facilitates navigation within the application by moving forward to the next state represented by the requested view.
    */
    public func displayView(view: AnyView, type: ViewType, addToHistory: Bool){
        DispatchQueue.main.async {
            if(addToHistory){
                self.previousViews.append(self.currentView)
            }
            self.currentView = (type, view)
        }
    }
    
    /**
     Attempts to revert to the most recently viewed view by updating `currentView` to the last item in the `previousViews` history stack.

     This method is responsible for navigating back to the previous view state in the application's view navigation history. It does so by setting the `currentView` to the last view stored in `previousViews`. This action effectively moves the application's UI "backwards" to a prior state.

     If the `previousViews` history stack is empty, indicating that there are no previous views to revert to, the method will display an alert informing the user of the unsuccessful navigation attempt.

     Usage:
     Calling this method triggers an attempt to navigate back to the previous view. If successful, `currentView` is updated; if unsuccessful, an alert is shown to the user.
    */
    public func displayPreviousView() {
        guard let previous = self.previousViews.popLast() else {
            self.showSimpleAlert(title: "Application Navigation Error", msg: Text("No previous view available to return to."))
            return
        }
        
        DispatchQueue.main.async {
            self.currentView = previous
        }
    }
    
    /**
     Prepares and queues an alert for display with specified title, message, and buttons.
     - Parameters:
        - title: The title of the alert.
        - msg: The message to be displayed within the alert.
        - buttons: An array of buttons, each with a label and an associated action. 
    */
    public func showAlert(title: String, msg: Text, buttons: [(label: String, action: () -> Void)]) {
        DispatchQueue.main.async {
            self.alertErrors.append((title, msg, buttons))
            if(self.alertErrors.count == 1) {
                self.showAlertError = true
            }
        }
    }
    
    /**
     A convenience method for showing an alert with a single "Cancel" button.
     - Parameters:
        - title: The title of the alert.
        - msg: The message to be displayed within the alert. 
    */
    public func showSimpleAlert(title: String, msg: Text){
        self.showAlert(
            title: title,
            msg: msg,
            buttons: [(label: "Cancel", action: { })
        ])
    }

    /** Clears the current alert from the queue, preparing the next alert for display if available. */
    public func clearAlertError() {
        if(!alertErrors.isEmpty) { alertErrors.removeFirst() }
        if(!alertErrors.isEmpty) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.showAlertError = true
            }
        }
    }
}

/** The `currentView` property is instrumental in constructing and managing the presentation of the
 application's current view, which includes the capability to display alerts as needed. It encapsulates
 the logic and structure required to render the active user interface component, ensuring that any
 associated alerts are properly integrated and presented alongside the view.

 This property dynamically determines the content displayed to the user at any given moment, facilitating
 the seamless integration of alerts into the visual context of the current view. By doing so, `currentView`
 serves a dual purpose: it not only dictates the primary visual content but also manages overlay components
 such as alerts, thereby enhancing the user's interaction experience by providing timely and relevant feedback
 or information through modal dialogs.

 In essence, `currentView` is central to the application's view management strategy, enabling the dynamic
 rendering of views while incorporating alert mechanisms directly within the user interface flow. This approach
 allows for an adaptive and responsive design, ensuring that the application can effectively communicate with
 the user through both its primary content and auxiliary alert messages.
*/
struct CurrentView: View {
    @ObservedObject var controller: ViewController

    var body: some View {
        ZStack {
            self.controller.currentView.1
        }.alert(self.controller.alertErrors.first?.0 ?? "Something unexpected happened...",
            isPresented: self.$controller.showAlertError,
            actions: {
                if let firstError = controller.alertErrors.first {
                    ForEach(firstError.2.indices, id: \.self) { index in
                        Button(firstError.2[index].label) {
                            firstError.2[index].action()
                            self.controller.clearAlertError()
                        }
                    }
                }
            },
            message: {
                if let firstError = controller.alertErrors.first {
                    firstError.1
                } else {
                    Text("Unknown error")
                }
            }
        ).onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            CRFly.shared.appData.djiDevConn = false
            CRFly.shared.droneController.connectToProduct()
        }
    }
}
