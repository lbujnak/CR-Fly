import Foundation

class ProjectManagementService : ObservableObject {
    @Published var projectList : [String] = ["<none>"]
    @Published var currentProject = project_info()
    @Published var mediaUploading = false
    
    private var projectGUIDs = [String : String]()
    private var httpHelper = HTTPHelper.shared
    
    struct project_info{
        var loaded : Bool = false
        var name : String = "<none>"
        var sessionID : String = ""
        var imageCnt : String = "Loading..."
        var componentCnt : String = "Loading..."
        var fileList : Set<String> = []
    }
    
    private var observerActive = false {
        didSet{
            if(self.observerActive) {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)){
                    self.checkTasks()
                }
            }
        }
    }
    
    private var tasks = Set<String>() {
        didSet{
            if(!self.observerActive) {
                if(tasks.count > 0) { self.observerActive = true }
            } else if(tasks.count == 0) { self.observerActive = false}
        }
    }
    
    private var taskCmd = [String : String]()
    
    func addTaskObserver(taskUUID : String, command : String){
        tasks.insert(taskUUID)
        taskCmd[taskUUID] = command
    }
    
    func checkTasks(){
        let urlEncodedArray = self.tasks.map { element in
            return element.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        }

        let joinedString = urlEncodedArray.joined(separator: ",")
        
        self.httpHelper.httpPattern(url: "/project/tasks?taskIDs=\(joinedString)", tol: 5, sessionID: self.currentProject.sessionID) {
            (httpData, data, response, error, scErr) in
            if(!self.observerActive){ return }
            
            let jsonArray = self.httpHelper.parseJsonData3D(data: httpData)
            if(!jsonArray!.isEmpty){
                for jsonData in jsonArray! {
                    if(jsonData["state"] as! String == "finished" && self.tasks.contains(jsonData["taskID"] as! String)){
                        self.doTask(task: jsonData["taskID"] as! String)
                    }
                }
            }
            if(self.observerActive){
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)){
                    self.checkTasks()
                }
            }
        }
    }
    
    func doTask(task: String){
        let cmd = self.taskCmd[task]!
        switch cmd {
            case "evaluateTemplate": do {
                var commandCnt = 0
                for (_, val) in self.taskCmd {
                    if(val == cmd){ commandCnt += 1 }
                }
                if(commandCnt == 1){
                    self.evalTemplate(){ error in
                        if(error != nil) {
                            GlobalAlertHelper.shared.createAlert(title: "Error Evaluating Template", msg: "Reopen project or contact dev, error : \(error!)")
                        }
                        DispatchQueue.main.async { self.mediaUploading = false }
                    }
                }
            }
            case "updateProjectInfo": do {
                self.updateProjectInfo(){ error in
                    if(error != nil) {
                        GlobalAlertHelper.shared.createAlert(title: "Error Evaluating Template", msg: "Reopen project or contact dev, error : \(error!)")
                    }
                }
            }
            default: do { return }
        }
        self.tasks.remove(task)
        self.taskCmd.removeValue(forKey: task)
    }
    
    func closeConn(){
        self.projectList.removeAll()
        self.projectGUIDs.removeAll()
        self.currentProject = project_info()
    }
    
    func refreshProjectList(completionHandler: @escaping (String?) -> Void){
        self.httpHelper.httpPattern(url: "/node/projects", tol: 5, sessionID: nil) { (httpData, data, response, error, scErr) in
            if(error != nil) {
                completionHandler(String(describing: error));
                return
            } else if(scErr) {
                completionHandler("Wrong http status: \(data!["message"]!)")
                return
            }
            
            let jsonArray = self.httpHelper.parseJsonData3D(data: httpData)
            DispatchQueue.main.async {
                self.projectList.removeAll()
                if(!self.currentProject.loaded) { self.projectList.append("<none>") }
                self.projectGUIDs.removeAll()
                if(!jsonArray!.isEmpty){
                    for jsonObj in jsonArray!{
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
                if(error != nil){ completionHandler(error!) }
                else {
                    self.openOrCreate(name: name){ error in
                        if(error != nil){ completionHandler(error!) }
                        else { completionHandler(nil) }
                    }
                }
                return
            }
        } else {
            self.openOrCreate(name: name){ error in
                if(error != nil){ completionHandler(error!) }
                else { completionHandler(nil) }
            }
        }
    }
    
    func openOrCreate(name: String, completionHandler: @escaping (String?) -> Void){
        //Create project
        if(!self.projectList.contains(name)){
            self.httpHelper.httpPattern(url: "/project/create", tol: 10, sessionID: nil) { (httpData, data, response, error, scErr) in
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
                        self.createTemplateFile(){ (error) in
                            if(error != nil){
                                GlobalAlertHelper.shared.createAlert(title: "Error Creating Template", msg: "Reopen project or contact dev, error : \(error!)")
                            }
                        }
                    }
                }
            }
        } else {
            if(self.projectGUIDs[name] == nil){
                completionHandler("Couldn't find guid for project \(name)")
                return
            }
            //Open project
            self.httpHelper.httpPattern(url: "/project/open?guid=\(self.projectGUIDs[name]!)", tol: 10, sessionID: nil) { (httpData, data, response, error, scErr) in
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
                    self.createTemplateFile(){ (error) in
                        if(error != nil){
                            GlobalAlertHelper.shared.createAlert(title: "Error Creating Template", msg: "Reopen project or contact dev, error : \(error!)")
                        }
                    }
                }
            }
        }
    }
    
    func saveProject(completionHandler: @escaping (String?) -> Void){
        self.httpHelper.httpPattern(url: "/project/save?name=\(self.currentProject.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)", tol: 10, sessionID: self.currentProject.sessionID) { (httpData, data, response, error, scErr) in
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
        self.httpHelper.httpPattern(url: "/project/close", tol: 10, sessionID: self.currentProject.sessionID) { (httpData, data, response, error, scErr) in
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
    
    func createTemplateFile(completionHandler: @escaping (String?) -> Void){
        let request = self.httpHelper.preparePostRequest(url: "/project/upload?name=cr-fly.tpl&folder=output", sessionID: self.currentProject.sessionID)
        
        let stringData = "$Using(\"CapturingReality.Report.ProjectInformationExportFunctionSet\")$Using(\"CapturingReality.Report.SfmExportFunctionSet\"){$ExportProjectInfo(\"name\":\"$(projectName)\",\"componentCount\":$(componentCount),\"imageCount\":$(imageCount),\"projectId\":\"$(projectGUID)\" $If(componentCount>0,,\"sfm\":{\"id\": \"$(actualComponentGUID)\",\"cameraCount\": $(cameraCount),\"pointCount\": $(pointCount),\"measurementCount\": $(measurementCount), \"displayScale\":$(displayScale)})) }"
        
        let reqData = Data(stringData.utf8)
        
        URLSession.shared.uploadTask(with: request, from: reqData) { (data, response, error) in
            if(error != nil) { completionHandler(String(describing: error!)) }
            else if((response as! HTTPURLResponse).statusCode != 200){
                completionHandler("Status code not as expected: \((response as! HTTPURLResponse).statusCode)")
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    self.evalTemplate(){ error in
                        if(error != nil){
                            GlobalAlertHelper.shared.createAlert(title: "Error Evaluating Template", msg: "Reopen project or contact dev, error : \(error!)")
                        }
                    }
                }
                completionHandler(nil)
            }
        }.resume()
    }
    
    func evalTemplate(completionHandler: @escaping (String?) -> Void){
        self.httpHelper.httpPattern(url: "/project/command?name=exportReport&param1=cr-fly_out.json&param2=cr-fly.tpl", tol: 10, sessionID: self.currentProject.sessionID){ (httpData, data, response, error, scErr) in
            if(error != nil){ completionHandler(String(describing: error!)) }
            else if(scErr){ completionHandler("\(String(describing: data!["message"]))") }
            else {
                self.addTaskObserver(taskUUID: data!["taskID"] as! String, command: "updateProjectInfo")
                completionHandler(nil)
            }
        }
    }
    
    func updateProjectInfo(completionHandler: @escaping (String?) -> Void){
        self.httpHelper.httpPattern(url: "/project/download?name=cr-fly_out.json&folder=output", tol: 10, sessionID: self.currentProject.sessionID){ (httpData, data, response, error, scErr) in
            
            if(error != nil){ completionHandler(String(describing: error!)) }
            else if(scErr){ completionHandler("\(String(describing: data!["message"]))") }
            else if(data == nil) { completionHandler("Unexpected null data") }
            else {
                DispatchQueue.main.async {
                    self.currentProject.imageCnt = String(describing: data!["imageCount"]!)
                    self.currentProject.componentCnt = String(describing: data!["componentCount"]!)
                }
                self.httpHelper.httpPattern(url: "/project/list?folder=data", tol: 10, sessionID: self.currentProject.sessionID){ (httpData, data, response, error, scErr) in
                    if(error != nil){ completionHandler(String(describing: error!)) }
                    else if(scErr){ completionHandler("\(String(describing: data!["message"]))") }
                    else {
                        self.currentProject.fileList.removeAll()
                        let jsonArray = self.httpHelper.parseJsonData1D(data: httpData)
                        if(!jsonArray!.isEmpty){
                            for jsonData in jsonArray! {
                                self.currentProject.fileList.insert(jsonData)
                            }
                        }
                        completionHandler(nil)
                    }
                }
            }
        }
    }
    
    func sendSingleImage(path : URL, completionHandler: @escaping (String?) -> Void) {
        if(self.currentProject.fileList.contains(path.lastPathComponent)){
            completionHandler(nil)
            return
        }
        
        let request = self.httpHelper.preparePostRequest(url:"/project/command?name=add&param1=\(path.lastPathComponent)",sessionID: self.currentProject.sessionID)
        
        URLSession.shared.uploadTask(with: request, fromFile: path) { (data, response, error) in
            let jsonData = self.httpHelper.parseJsonData2D(data: data)
            if(error != nil){ completionHandler(String(describing: error!)) }
            else if((response as! HTTPURLResponse).statusCode != 202) {
                if(jsonData != nil && jsonData!["message"] != nil) { completionHandler(jsonData!["message"] as? String) }
                else { completionHandler("Unknown error, wrong status code: \((response as! HTTPURLResponse).statusCode)") }
            } else {
                self.addTaskObserver(taskUUID: jsonData!["taskID"] as! String, command: "evaluateTemplate")
                completionHandler(nil)
            }
            
        }.resume()
    }
}
