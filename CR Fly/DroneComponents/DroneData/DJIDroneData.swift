import DJISDK
import Foundation

/**
 `DJIDroneData` is a class designed to manage and expose the state of a DJI drone within an application, making it observable to SwiftUI views or other components that need to react to changes in drone status.
 
 - This class is typically utilized within a broader drone management system in an application that integrates with DJI drones. It provides a centralized point for monitoring the connection status of a drone.
 */
public class DJIDroneData: ObservableObject {
    /// An optional `DJIBaseProduct` that represents the connected DJI drone. This property is `nil` when no drone is connected and is updated to reflect the currently connected device when a drone links with the application. This enables the application to access detailed information about the drone, such as model, capabilities, and status.
    @Published var device: DJIBaseProduct? = nil
}
