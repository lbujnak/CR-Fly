import SwiftUI
import DJISDK

@main
struct AppController: App {
    @ObservedObject var viewController = CRFly.shared.viewController
    
    var body: some Scene {
        WindowGroup{
            viewController.getView()
        }
    }
}

public class CRFly: ObservableObject {
    static var shared = CRFly()
    
    //Data
    @Published var appData = ApplicationData()
    
    //Controllers
    @Published var viewController = ViewController()
}
