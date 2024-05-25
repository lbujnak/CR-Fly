import SwiftUI

/// `MainView` serves as the primary user interface component in the application, displaying background imagery, location data, and navigation buttons to various views like photo albums and 3D scenes.
public struct MainView: AppearableView {
    /// Reference to the `ViewController` responsible for managing navigation, presentation of different views within the application and displaying errors.
    private let viewController: ViewController
    
    /// Reference to an instance of `DroneController` that facilitates communication and control of the drone.
    private let droneController: DroneController
    
    /// Reference to `LocationController`, that manages and updates the location data used within the view.
    private var locationController: LocationController
    
    /// Reference to the observable data class `DroneData` containing drone's operational data.
    @ObservedObject private var droneData: DroneData
    
    /// Reference to observable object `SharedData` which contains common data used across different components of the application.
    @ObservedObject private var sharedData: SharedData
    
    /// Initializes the `MainView`.
    public init(viewController: ViewController, droneController: DroneController, sharedData: SharedData) {
        self.viewController = viewController
        self.droneController = droneController
        self.droneData = droneController.droneData
        self.sharedData = sharedData
        self.locationController = LocationController(sharedData: sharedData)
    }
    
    /// Called when the object becomes visible within the user interface.
    public func appear() { }
    
    /// Called when the object is no longer visible within the user interface.
    public func disappear() { }
    
    /// Constructs the main interface of the application, combining background imagery, location indicators, and navigation options into a cohesive user interface.
    public var body: some View {
        ZStack {
            GeometryReader { proxy in
                Image("background").resizable().scaledToFill().frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            }.ignoresSafeArea()
            
            VStack {
                HStack {
                    if self.sharedData.currentLocationAddress == "" {
                        Image(systemName: "location.magnifyingglass").bold()
                        Text("Locating...").bold()
                    } else {
                        Image(systemName: "location.fill").bold()
                        Text(self.sharedData.currentLocationAddress).bold()
                    }
                    Spacer()
                }.padding([.top], 30)
                
                Spacer()
                HStack(spacing: 40) {
                    Button {
                        self.viewController.displayView(type: .albumView, addPreviousToHistory: true)
                    } label: {
                        Image(systemName: "photo")
                        Text("Photo Album")
                    }
                    
                    Button {
                        self.viewController.displayView(type: .sceneView, addPreviousToHistory: true)
                    } label: {
                        Image("realitycapture-logo").resizable().frame(width: 20, height: 20)
                        Text("3D Scene")
                    }
                    
                    Spacer()
                    Button {
                        self.droneController.openFPVView()
                    } label: {
                        Text(self.droneData.deviceConnected ? "Let's FLY" : "Not Connected").font(.callout)
                    }.padding([.top, .bottom], 15).padding([.leading, .trailing], 30).frame(width: 220)
                        .background(RoundedRectangle(cornerRadius: 10).stroke(.white, lineWidth: 2).fill(self.droneData.deviceConnected ? .blue : .black.opacity(0.7)))
                        .disabled(!self.droneData.deviceConnected)
                    
                }.padding([.bottom], 20)
            }.foregroundColor(.white).padding([.leading, .trailing], 20)
        }
    }
}
