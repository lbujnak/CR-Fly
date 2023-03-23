import SwiftUI
import Foundation

class GlobalAlertHelper : ObservableObject{
    @Published var active = false
    @Published var title : Text = Text("")
    @Published var msg : Text = Text("")
    
    @ObservedObject static var shared = GlobalAlertHelper()
    
    //TODO:: Implementovat zasobnik alertov
    
    
    func createAlert(title : String, msg : String){
        self.title = Text(title)
        self.msg = Text(msg)
        self.active = true
    }
}

