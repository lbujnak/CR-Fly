import SwiftUI

public enum ViewType {
    case empty
    case mainView
    case scannerView
    case albumView
    case albumMediaPreview
}

public class ViewController: NSObject, ObservableObject {
    
    //UI CommandQueue
    private var isExecutingCommand = false
    private var commandQueue: [Command] = []
    
    //Error handling
    @Published var alertErrors: [(String, Text, [(label: String, action: () -> Void)])] = []
    @Published var showAlertError: Bool = false
    
    //View change, etc..
    @Published var currentView: AnyView = AnyView(EmptyView())
    private var currentViewType: ViewType = .empty
    private var viewMap: [ViewType : AnyView] = [:]
    
    //MARK: UI Command Queue
    /*func pushCommand(command: Command) {
        self.commandQueue.append(command)
        if(!self.isExecutingCommand) {
            processNextCommand()
        }
    }
    
    private func processNextCommand() {
        guard !self.isExecutingCommand, !self.commandQueue.isEmpty else { return }

        self.isExecutingCommand = true
        let command = self.commandQueue.removeFirst()
        command.execute {
            self.isExecutingCommand = false
            self.processNextCommand()
        }
    }*/
    
    func addView(type: ViewType, view: AnyView) {
        self.viewMap[type] = view
    }
    
    func getView() -> some View {
        CurrentView(controller: self)
    }
    
    func getViewType() -> ViewType {
        return self.currentViewType
    }
    
    func changeView(type: ViewType){
        DispatchQueue.main.async {
            self.currentView = self.viewMap[type]!
            self.currentViewType = type
        }
    }
    
    func changeView(view: AnyView, type: ViewType){
        DispatchQueue.main.async {
            self.currentView = view
            self.currentViewType = type
        }
    }
    
    func showAlert(title: String, msg: Text, buttons: [(label: String, action: () -> Void)]) {
        DispatchQueue.main.async {
            self.alertErrors.append((title, msg, buttons))
            if(self.alertErrors.count == 1) {
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
        if(!alertErrors.isEmpty) { alertErrors.removeFirst() }
        if(!alertErrors.isEmpty) {
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
        }.alert(self.controller.alertErrors.first?.0 ?? "Something unexpected happened...",
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
        ).onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            CRFly.shared.appData.djiDevConn = false
            CRFly.shared.droneController.connectToProduct()
        }
    }
}
