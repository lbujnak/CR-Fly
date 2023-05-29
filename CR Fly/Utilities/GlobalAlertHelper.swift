import SwiftUI
import Foundation

class GlobalAlertHelper : ObservableObject{
    @Published var active = false
    @Published var title : Text = Text("")
    @Published var msg : Text = Text("")
    
    @ObservedObject static var shared = GlobalAlertHelper()
    
    //TODO:: Implementovat zasobnik alertov
    
    func createAlert(title: String, msg: String){
        DispatchQueue.main.async {
            self.title = Text(title)
            self.msg = Text(msg)
            self.active = true
        }
    }
    
    func showError(msg: String){
        DispatchQueue.main.async {
            self.title = Text("Error")
            self.msg = Text(msg)
            self.active = true
        }
    }
}

