import Foundation
import Network

/**
 `HTTPConnectionStateObserver` is a protocol designed to define an observer for HTTP connection state changes. Implementing this protocol allows an object to monitor and respond to changes in the network connection state of an HTTP connection.
 
 - Usage: This protocol is typically used in network management systems where it is crucial to react to changes in connection state dynamically. For example, an object conforming to this protocol might update user interface elements or adjust application behavior based on the network availability or specific network conditions. Observers might be registered with an HTTP connection manager that tracks state changes. When a change occurs, the manager would call `observeConnection` on all registered observers.
 
 - Note: This protocol is part of a broader system for managing HTTP connections and may interact with other components that handle the specifics of network communication and state management.
 */
public protocol HTTPConnectionStateObserver {
    /// Returns a string that uniquely identifies the observer. This unique ID can be used to manage subscriptions to the connection state updates, ensuring that updates are sent to the correct observer.
    func getUniqueId() -> String
    
    /** Called when there is a change in the HTTP connection's state.
    - Parameter newState: An enum value of type `HTTPConnection.HTTPConnectionState`, representing the new state of the HTTP connection.
     */
    func observeConnection(newState: HTTPConnection.HTTPConnectionState)
}
