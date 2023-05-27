import SwiftUI
import Foundation
import Network
import DJISDK

class RCNodeCommunicationService : NSObject, ObservableObject {
    
    @ObservedObject static var shared = RCNodeCommunicationService()
    @ObservedObject var libComm = ProductCommunicationService.shared.libController
    
    @Published var ip = "192.168.10.15" //"192.168.11.100"
    @Published var autorized = false;//false;
    @Published var connectionLost = false;
    @Published var authToken = "674746F1-C361-413B-B427-BD769E7BE96E" //"383F0345-9E6E-461F-907F-534337987967"
    @Published var projectList : [String] = ["<none>"]
    @Published var projectGUIDs = [String : String]()
    
    @Published var currentProject = project_info()
    
    private var retries = 0;
    private var checkerOn = false;
    
    struct project_info{
        var loaded : Bool = false
        var name : String = "<none>"
        var sessionID : String = ""
        var imageCnt : String = "Loading..."
        var componentCnt : String = "Loading..."
    }
    
    func httpPattern(url: String, expSC : Int, timeOutLimit: Double, withSessionId : String?, completionHandler: @escaping (Data?,[String: Any]?, HTTPURLResponse?, Error?, Bool) -> Void){
        let url = URL(string: "http://\(self.ip):8000\(url)")!
        var request = URLRequest(url: url, timeoutInterval: timeOutLimit);
        
        request.setValue("close", forHTTPHeaderField: "Connection")
        request.setValue("Bearer \(self.authToken)", forHTTPHeaderField: "Authorization")
        if(withSessionId != nil){ request.setValue("\(withSessionId!)", forHTTPHeaderField: "Session") }
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            let httpResponse = response as? HTTPURLResponse
            var jsonData : [String: Any]? = nil
            if(data != nil){
                jsonData = try? JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
            }
            if(httpResponse == nil){ completionHandler(data,jsonData,httpResponse,error,true) }
            else { completionHandler(data,jsonData,httpResponse,error,httpResponse!.statusCode != expSC) }
        }.resume()
    }
    
    func connectUserToRc(completionHandler: @escaping (String?) -> Void){
        self.httpPattern(url: "/node/connectuser", expSC: 200, timeOutLimit: 2, withSessionId: nil) { (httpData, data, response, error, scErr) in
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
                    /*DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                        self.checkForConnection()
                    }*/
                }
            }
            completionHandler(nil)
        }
    }
    
    //TODO ak je project loaded -> switch na /project/status
    func checkForConnection(){
        if(!self.autorized){
            self.checkerOn = false
            return
        }
        
        self.httpPattern(url: "/node/status", expSC: 200, timeOutLimit: 10, withSessionId: nil){ (httpData, data, response, error, scErr) in
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
                if(self.autorized) { self.checkForConnection() }
            }
        }
    }
    
    func closeConnection(){
        DispatchQueue.main.async {
            ViewHelper.shared.rcContMode = false
            self.autorized = false;
            self.currentProject = project_info()
            self.projectList.removeAll()
            self.projectGUIDs.removeAll()
            self.connectionLost = false
            self.retries = 0
            self.connectionLost = false
            self.checkerOn = false
        }
    }
    
    func refreshProjectList(completionHandler: @escaping (String?) -> Void){
        self.httpPattern(url: "/node/projects", expSC: 200, timeOutLimit: 5, withSessionId: nil) { (httpData, data, response, error, scErr) in
            if(error != nil) {
                completionHandler(String(describing: error));
                return
            } else if(scErr) {
                completionHandler("Wrong http status: \(data!["message"]!)")
                return
            }
            
            let jsonArray = try! JSONSerialization.jsonObject(with: httpData!, options: []) as! [[String: Any]]
            DispatchQueue.main.async {
                self.projectList.removeAll()
                if(!self.currentProject.loaded) { self.projectList.append("<none>") }
                self.projectGUIDs.removeAll()
                if(!jsonArray.isEmpty){
                    for jsonObj in jsonArray{
                        let name = jsonObj["name"] as! String
                        let guid = jsonObj["guid"] as! String
                        
                        self.projectList.append(name)
                        self.projectGUIDs[name] = guid
                    }
                }
                completionHandler(nil)
            }
        }
    }
    
    func changeProject(name : String, completionHandler: @escaping (String?) -> Void){
        if(name == self.currentProject.name) {
            completionHandler(nil)
            return
        }
        
        //Close project
        if(self.currentProject.loaded){
            self.closeProject(){ error in
                if(error != nil){
                    completionHandler(error!)
                } else {
                    self.openOrCreate(name: name){ error in
                        if(error != nil){
                            completionHandler(error!)
                        }
                        completionHandler(nil)
                    }
                }
                return
            }
        } else {
            self.openOrCreate(name: name){ error in
                if(error != nil){
                    completionHandler(error!)
                }
                completionHandler(nil)
            }
        }
    }
    
    func openOrCreate(name: String, completionHandler: @escaping (String?) -> Void){
        //Create project
        if(!self.projectList.contains(name)){
            self.httpPattern(url: "/project/create", expSC: 201, timeOutLimit: 10, withSessionId: nil) { (httpData, data, response, error, scErr) in
                if(error != nil) {
                    completionHandler(String(describing: error));
                    return
                } else if(scErr) {
                    completionHandler("Wrong http status: \(data!["message"]!)")
                    return
                }
                
                var encName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                if(encName == ""){
                    encName = "cr_fly_\(String(describing: (DateFormatter().string(from: Date()))))"
                }
                
                DispatchQueue.main.async {
                    self.currentProject.loaded = true
                    self.currentProject.name = encName!
                    self.currentProject.sessionID = response!.value(forHTTPHeaderField: "Session")!
                    self.saveProject(){ error in
                        if(error != nil){
                            completionHandler(error!)
                            return
                        }
                        self.projectList.removeFirst()
                        
                        completionHandler(nil)
                        self.updateProjectInfo()
                    }
                }
            }
        } else {
            if(self.projectGUIDs[name] == nil){
                completionHandler("Couldn't find guid for project \(name)")
                return
            }
            //Open project
            self.httpPattern(url: "/project/open?guid=\(self.projectGUIDs[name]!)", expSC: 200, timeOutLimit: 10, withSessionId: nil) { (httpData, data, response, error, scErr) in
                if(error != nil) {
                    completionHandler(String(describing: error));
                    return
                } else if(scErr) {
                    completionHandler("Wrong http status: \(data!["message"]!)")
                    return
                }
                DispatchQueue.main.async {
                    self.projectList.removeFirst()
                    self.currentProject.loaded = true
                    self.currentProject.name = name
                    self.currentProject.sessionID = self.projectGUIDs[name]!
                    
                    completionHandler(nil)
                    self.updateProjectInfo()
                }
            }
        }
    }
    
    func saveProject(completionHandler: @escaping (String?) -> Void){
        self.httpPattern(url: "/project/save?name=\(self.currentProject.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)", expSC: 202, timeOutLimit: 10, withSessionId: self.currentProject.sessionID) { (httpData, data, response, error, scErr) in
            if(error != nil) {
                completionHandler(String(describing: error));
                return
            } else if(scErr) {
                completionHandler("Wrong http status: \(data!["message"]!)")
                return
            }
            completionHandler(nil)
        }
    }
    
    func closeProject(completionHandler: @escaping (String?) -> Void){
        self.httpPattern(url: "/project/close", expSC: 200, timeOutLimit: 10, withSessionId: self.currentProject.sessionID) { (httpData, data, response, error, scErr) in
            if(error != nil) {
                completionHandler(String(describing: error));
                return
            } else if(scErr) {
                completionHandler("Wrong http status: \(data!["message"]!)")
                return
            }
            DispatchQueue.main.async {
                self.currentProject = project_info()
                self.refreshProjectList(){ error in
                    if(error != nil){
                        completionHandler(error!)
                        return
                    }
                    completionHandler(nil)
                }
            }
        }
    }
    
    func updateProjectInfo(){
        var updError : String? = nil
        self.createTemplateFile(){ (error) in
            if(error != nil){
                updError = String(describing: error!)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    self.evalTemplate(){ (error) in
                        if(error != nil){
                            updError = String(describing: error!)
                        }
                    }
                }
            }
        }
        if(updError != nil){
            DispatchQueue.main.async {
                self.currentProject.imageCnt = "error"
                self.currentProject.componentCnt = "error"
                GlobalAlertHelper.shared.createAlert(title: "Update project info error", msg: updError!)
            }
        }
    }
    
    func createTemplateFile(completionHandler: @escaping (String?) -> Void){
        let url = URL(string: "http://\(self.ip):8000/project/upload?name=cr-fly.tpl&folder=output")!
        
        var request = URLRequest(url: url, timeoutInterval: 2);
        request.setValue("close", forHTTPHeaderField: "Connection")
        request.setValue("Bearer \(self.authToken)", forHTTPHeaderField: "Authorization")
        request.setValue((self.currentProject.sessionID), forHTTPHeaderField: "Session")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        let stringData = "$Using(\"CapturingReality.Report.ProjectInformationExportFunctionSet\")$Using(\"CapturingReality.Report.SfmExportFunctionSet\"){$ExportProjectInfo(\"name\":\"$(projectName)\",\"componentCount\":$(componentCount),\"imageCount\":$(imageCount),\"projectId\":\"$(projectGUID)\" $If(componentCount>0,,\"sfm\":{\"id\": \"$(actualComponentGUID)\",\"cameraCount\": $(cameraCount),\"pointCount\": $(pointCount),\"measurementCount\": $(measurementCount), \"displayScale\":$(displayScale)})) }"
        
        let reqData = Data(stringData.utf8)
        
        URLSession.shared.uploadTask(with: request, from: reqData) { (data, response, error) in
            if(error != nil) { completionHandler(String(describing: error!)) }
            else if((response as! HTTPURLResponse).statusCode != 200){
                completionHandler("Status code not as expected: \((response as! HTTPURLResponse).statusCode)")
            } else { completionHandler(nil) }
        }.resume()
    }
    
    func evalTemplate(completionHandler: @escaping (String?) -> Void){
        self.httpPattern(url: "/project/command?name=exportReport&param1=cr-fly_out.json&param2=cr-fly.tpl", expSC: 202, timeOutLimit: 10, withSessionId: self.currentProject.sessionID){ (httpData, data, response, error, scErr) in
            if(error != nil){ completionHandler(String(describing: error!)) }
            else if(scErr){ completionHandler("\(String(describing: data!["message"]))") }
            else {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)){
                    self.downloadReportFile() { (error) in
                        completionHandler(error)
                    }
                }
            }
        }
    }
    
    func downloadReportFile(completionHandler: @escaping (String?) -> Void){
        self.httpPattern(url: "/project/download?name=cr-fly_out.json&folder=output", expSC: 200, timeOutLimit: 10, withSessionId: self.currentProject.sessionID){ (httpData, data, response, error, scErr) in
            
            if(error != nil){ completionHandler(String(describing: error!)) }
            else if(scErr){ completionHandler("\(String(describing: data!["message"]))") }
            else {
                if(data != nil){
                    DispatchQueue.main.async {
                        self.currentProject.imageCnt = String(describing: data!["imageCount"]!)
                        self.currentProject.componentCnt = String(describing: data!["componentCount"]!)
                    }
                }
                completionHandler(nil)
            }
        }
    }
    
    func sendSingleImage(path : URL, completionHandler: @escaping (String?) -> Void) {
        let url = URL(string: "http://\(self.ip):8000/project/command?name=add&param1="+path.lastPathComponent)!
        
        var request = URLRequest(url: url, timeoutInterval: 2);
        request.setValue("close", forHTTPHeaderField: "Connection")
        request.setValue("Bearer \(self.authToken)", forHTTPHeaderField: "Authorization")
        request.setValue((self.currentProject.sessionID), forHTTPHeaderField: "Session")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        URLSession.shared.uploadTask(with: request, fromFile: path) { (data, response, error) in
            if(error != nil){ completionHandler(String(describing: error!)) }
            //TODO:: Duplikaciu zatial ignorujem
            else if((response as! HTTPURLResponse).statusCode != 202 && (response as! HTTPURLResponse).statusCode != 409) {
                var jsonData : [String: Any]? = nil
                if(data != nil){
                    jsonData = try? JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                }
                if(jsonData != nil && jsonData!["message"] != nil) { completionHandler(jsonData!["message"] as? String) }
                else { completionHandler("Unknown error, wrong status code: \((response as! HTTPURLResponse).statusCode)") }
            } else { completionHandler(nil) }
            
        }.resume()
    }
}
