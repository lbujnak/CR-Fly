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
    
    func connectUserToRc(ip : String, authToken : String, completionHandler: @escaping (String?) -> Void){
        self.httpHelper.changeParams(ip: ip, authToken: authToken)
        self.httpHelper.httpPattern(url: "/node/connectuser", tol: 2, sessionID: nil) { (httpData, data, response, error, scErr) in
            if(error != nil) {
                completionHandler(String(describing: error));
                return
            } else if(scErr) {
                completionHandler("Wrong http status: \(data!["message"]!)")
                return
            }
            
            DispatchQueue.main.async {
                self.autorized = true
                if(!self.checkerOn){
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                        self.checkNodeStatus()
                    }
                }
            }
            completionHandler(nil)
        }
    }
    
    func checkNodeStatus(){
        if(!self.autorized){
            self.checkerOn = false
            return
        }
        self.httpHelper.httpPattern(url: "/node/status", tol: 10, sessionID: nil){ (httpData, data, response, error, scErr) in
            DispatchQueue.main.async {
                if((error != nil || scErr) && self.retries < 3){
                    self.retries += 1;
                    if(self.retries == 1){
                        self.connectionLost = true
                        GlobalAlertHelper.shared.createAlert(title: "RC Node Error", msg: "Lost connection to RC Node, will try 3 connections within 30 seconds and then disconnect. Any update of project until connection is established will be ignored.")
                    }
                } else if((error != nil || scErr) && self.retries >= 3) {
                    self.closeConnection()
                    return
                } else if(error == nil && !scErr){
                    if(self.retries > 0){
                        self.retries = 0;
                        self.connectionLost = false
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
