import SwiftUI
import DJISDK
@main
struct AppController: App {
    
    @ObservedObject var viewHelper = ViewHelper.shared
    @ObservedObject var djiService = ProductCommunicationService.shared
    @ObservedObject var rcNodeService = RCNodeCommunicationService.shared
    
    init(){
        self.djiService.registerWithSDK()
    }
    
    var body: some Scene {
        WindowGroup {
            if(self.viewHelper.fpvMode){
                DroneFPVView()
            }
            else if(self.viewHelper.libMode){
                if(self.viewHelper.libModePicked){
                    LibraryPreviewView()
                }
                else { LibraryView() }
            }
            else if(self.viewHelper.rcContMode){
                RCNodeView()
            }
            else{ MainView() }
        }
    }
}
