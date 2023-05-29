import SwiftUI
import Foundation
import Network
import DJISDK

class RCNodeCommunicationService : NSObject, ObservableObject {
    
    @ObservedObject static var shared = RCNodeCommunicationService()
    
    @Published var autorized = false
    @Published var connectionLost = false
    
    private var retries = 0
    private var checkerOn = false
    
    private var httpHelper = HTTPHelper.shared
    @Published var projectManagement = ProjectManagementService()
    
    func connectUserToRc(ip : String, authToken : String, completionHandler: @escaping (Bool) -> Void){
        self.httpHelper.changeParams(ip: ip, authToken: authToken)
        self.httpHelper.httpPattern(url: "/node/connectuser", tol: 2, sessionID: nil) { (httpData, data, response, valid) in
            if(valid) {
                DispatchQueue.main.async {
                    self.autorized = true
                    if(!self.checkerOn){
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                            self.checkNodeStatus()
                        }
                    }
                }
            }
            completionHandler(valid)
        }
    }
    
    func checkNodeStatus(){
        if(!self.autorized){
            self.checkerOn = false
            return
        }
        self.httpHelper.httpPattern(url: "/node/status", tol: 5, sessionID: nil){ (httpData, data, response, valid) in
            DispatchQueue.main.async {
                if(!valid && self.retries < 3){
                    self.retries += 1;
                    if(self.retries == 1){ self.connectionLost = true }
                } else if(!valid && self.retries >= 3) {
                    self.closeConnection()
                    return
                } else if(valid){
                    if(self.retries > 0){
                        self.retries = 0;
                        self.connectionLost = false
                    }
                    if(data != nil) {
                        if(self.projectManagement.currentProject.loaded){
                            let sfmData = data!["sessionIds"] as! [String]
                            if(!sfmData.contains(self.projectManagement.currentProject.sessionID)){
                                self.projectManagement.closeConn()
                                GlobalAlertHelper.shared.createAlert(title: "RC Node", msg: "RC Node was restarted and connection to project was closed")
                                return
                            }
                        }
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                if(self.autorized) { self.checkNodeStatus() }
            }
        }
    }
    
    func closeConnection(){
        DispatchQueue.main.async {
            ViewHelper.shared.rcContMode = false
            self.retries = 0
            self.checkerOn = false
            self.autorized = false;
            self.connectionLost = false
            self.projectManagement.closeConn()
        }
    }
}
