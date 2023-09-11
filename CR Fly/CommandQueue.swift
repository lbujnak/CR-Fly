import SwiftUI

public class CommandQueue: NSObject, ObservableObject {
    
    @ObservedObject static var shared = CommandQueue()
    
}
