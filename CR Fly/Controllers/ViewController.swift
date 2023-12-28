import SwiftUI

public enum ViewType {
    case mainView
    case scannerView
    case albumView
}

public class ViewController: NSObject, ObservableObject {
    
    //Error handling
    @Published var alertErrors: [(String, Text, [(label: String, action: () -> Void)])] = []
    @Published var showAlertError: Bool = false
    
    //View change, etc..
    @Published var currentView: AnyView = AnyView(EmptyView())
    private var viewMap: [ViewType : AnyView] = [:]
    
    func addView(type: ViewType, view: AnyView) {
        self.viewMap[type] = view
    }
    
    func getView() -> some View {
        CurrentView(controller: self)
    }
    
    func changeView(type: ViewType){
        DispatchQueue.main.async {
            self.currentView = self.viewMap[type]!
        }
    }
    
    func showAlert(title: String, msg: Text, buttons: [(label: String, action: () -> Void)]) {
        DispatchQueue.main.async {
            self.alertErrors.append((title, msg, buttons))
            if self.alertErrors.count == 1 {
                self.showAlertError = true
            }
        }
    }
    
    func showSimpleAlert(title: String, msg: Text){
        self.showAlert(
            title: title,
            msg: msg,
            buttons: [(label: "Cancel", action: { })
        ])
    }

    func clearAlertError() {
        if !alertErrors.isEmpty { alertErrors.removeFirst() }
        if !alertErrors.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.showAlertError = true
            }
        }
    }
}

struct CurrentView: View {
    @ObservedObject var controller: ViewController

    var body: some View {
        ZStack {
            self.controller.currentView
        }
        .alert(self.controller.alertErrors.first?.0 ?? "Something unexpected happened...",
            isPresented: self.$controller.showAlertError,
            actions: {
                if let firstError = controller.alertErrors.first {
                    ForEach(firstError.2.indices, id: \.self) { index in
                        Button(firstError.2[index].label) {
                            firstError.2[index].action()
                            self.controller.clearAlertError()
                        }
                    }
                }
            },
            message: {
                if let firstError = controller.alertErrors.first {
                    firstError.1
                } else {
                    Text("Unknown error")
                }
            }
        )
    }
}
