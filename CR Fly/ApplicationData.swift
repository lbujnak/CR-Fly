import SwiftUI

public class ApplicationData : NSObject, ObservableObject {
    
    @ObservedObject static var shared = ApplicationData()
    
    @Published var orientation: Int = 0
    
    //MARK: MainView Data
    
    //DJI
    @Published var djiSdkReg = false
    @Published var djiDevConn = false
    @Published var djiBridgeMode = false //false
    @Published var djiBridgeIP = "192.168.10.42"
    
    //RC
    @Published var rcNodeConn = false
    @Published var rcNodeIP : [String] = ["192.168.10.15","192.168.11.100"]
    @Published var rcAuthTkn = "674746F1-C361-413B-B427-BD769E7BE96E" // "383F0345-9E6E-461F-907F-534337987967"
}
