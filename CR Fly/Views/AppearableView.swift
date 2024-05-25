import SwiftUI

/// A protocol `AppearableView` defines an interface for view components that require executing specific actions when they appear or disappear on the user interface. This protocol extends the basic `View` protocol, indicating that all conforming types must be capable of being displayed as part of a graphical user interface, thus enabling flexible integration into various UI architectures.
public protocol AppearableView: View {
    /// Called when the view becomes visible within the user interface. Implementations should include logic for initialization, resource setup, or starting animations that are relevant for the object's appearance.
    func appear()
    
    /// Called when the view is no longer visible within the user interface. Implementations should handle cleanup or release of resources, stopping of animations, or other necessary actions to properly hide the object.
    func disappear()
}

extension EmptyView: AppearableView {
    public func appear() {}
    public func disappear() {}
    
    public var body: some View {
        VStack {}
    }
}
