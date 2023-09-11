import SwiftUI

protocol ContentViewProtocol {
    func getView() -> AnyView
}

public enum ViewType {
    case mainView
    case scannerView
}

public class ViewController: NSObject, ObservableObject {
    
    @ObservedObject static var shared = ViewController()
    
    @Published private var currSceneId = 0
    private var viewMap: [ViewType : Int] = [.mainView: 0, .scannerView: 1]
    private let views: [AnyView] = [AnyView(MainView()),AnyView(ScannerView())]
    
    func getView() -> some View {
        return self.views[self.currSceneId]
            .onAppear(){
                ApplicationData.shared.orientation = UIDevice.current.orientation.rawValue
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            if(UIDevice.current.orientation.rawValue == 4 || UIDevice.current.orientation.rawValue == 3){
                ApplicationData.shared.orientation = UIDevice.current.orientation.rawValue
            }
          }
    }
    
    func changeView(type: ViewType){
        self.currSceneId = self.viewMap[type]!
    }
}
