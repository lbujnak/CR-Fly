import SwiftUI
import DJISDK

@main
struct AppController: App {
    
    @ObservedObject var viewController = ViewController.shared
    
    var body: some Scene {
        WindowGroup{
            viewController.getView()
        }
    }
}
