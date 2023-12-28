import SwiftUI
import DJISDK

@main
struct AppController: App {
    @ObservedObject var viewController = CRFly.shared.viewController
    
    //TODO: load saved media
    
    init(){
        CRFly.shared.droneController.registerWithSDK()
        
        self.viewController.addView(type: .mainView, view: AnyView(MainView()))
        self.viewController.addView(type: .scannerView, view: AnyView(ScannerView()))
        self.viewController.addView(type: .albumView, view: AnyView(AlbumView()))
        self.viewController.changeView(type: .mainView)
    }
    
    var body: some Scene {
        WindowGroup{
            viewController.getView()
        }
    }
}
