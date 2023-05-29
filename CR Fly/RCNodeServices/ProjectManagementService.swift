import Foundation

class ProjectManagementService : ObservableObject {
    @Published var projectList : [String] = ["<none>"]
    @Published var currentProject = project_info()
    
    @Published var evaluatingProjectInfo = false
    @Published var evaluatingPoints = false
    @Published var evaluatingCameras = false
    
    @Published var aligningImages = false
    @Published var calculatingModel = false
    @Published var exportingModel = false
    
    @Published var projectCmds = false
    @Published var projectFirstLoad = false
    
    @Published var currentScene = 0
    @Published var mediaUploading = false
    @Published var stat_uploaded = 0
    @Published var stat_total = 0
    
    @Published var hasLoadedNModel = false
    @Published var hasLoadedPModel = false
    
    @Published var savable = false
    private var projectGUIDs = [String : String]()
    private var httpHelper = HTTPHelper.shared
    private var taskCmd = [String : String]()
    private var libraryURL : URL = URL(filePath: NSHomeDirectory())
    
    init() {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        self.libraryURL = URL(string: paths)!.appendingPathComponent("Calculated Models")
        if !FileManager.default.fileExists(atPath: self.libraryURL.path) {
            do {
                try FileManager.default.createDirectory(atPath: self.libraryURL.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
                return
            }
        }
        self.savable = true
    }
    
    struct project_info{
        var loaded : Bool = false
        var name : String = "<none>"
        var sessionID : String = ""
        var imageCnt : Int = 0
        var componentCnt : Int = 0
        var cameraCnt : Int = 0
        var pointCnt : Int = 0
        var measurementCnt : Int = 0
        var displayScale : Int = 1
        var sfmID : String = ""
        var fileList : Set<String> = []
    }
    
    @Published var observerActive = false {
        didSet{
            if(self.observerActive) {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)){
                    self.checkTasks()
                }
            }
        }
    }
    
    private var tasks = Set<String>() {
        didSet{
            if(!self.observerActive) {
                if(tasks.count > 0) { DispatchQueue.main.async { self.observerActive = true }}
            } else if(tasks.count == 0) { DispatchQueue.main.async { self.observerActive = false }}
        }
    }
    
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
            (httpData, data, response, valid) in
            if(!valid) { self.observerActive = false }
            else{
                if(!self.observerActive){ return }
                
                let jsonArray = self.httpHelper.parseJsonData3D(data: httpData)
                if(jsonArray != nil && !jsonArray!.isEmpty){
                    for jsonData in jsonArray! {
                        if(jsonData["state"] as! String == "finished" && self.tasks.contains(jsonData["taskID"] as! String)){
                            self.doTask(task: jsonData["taskID"] as! String, myCmd: nil)
                        } else if(jsonData["state"] as! String == "failed"){
                            GlobalAlertHelper.shared.createAlert(title: "Task Error", msg: "Error executing task: \(String(describing: jsonData["taskID"]!)), error: \(String(describing: jsonData["errorMessage"]!))")
                            self.tasks.remove((jsonData["taskID"] as! String))
                            self.taskCmd.removeValue(forKey: (jsonData["taskID"] as! String))
                        }
                    }
                }
                if(self.observerActive){
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)){
                        self.checkTasks()
                    }
                }
            }
        }
    }
    
    func doTask(task: String, myCmd : String?){
        var cmd : String
        if(myCmd == nil){
            cmd = self.taskCmd[task]!
        } else { cmd = myCmd! }
        switch cmd {
            case "addImage": do {
                var commandCnt = 0
                for (_, val) in self.taskCmd {
                    if(val == cmd){ commandCnt += 1 }
                }
                
                DispatchQueue.main.async { self.stat_uploaded += 1 }
                if(commandCnt == 1){ self.evalInfoTemplate() }
            }
            
            case "updateProjectInfo": do { self.updateProjectInfo() }
            
            case "updateScene": do {
                DispatchQueue.main.async {
                    self.aligningImages = false
                    self.evaluatingPoints = true
                    self.evaluatingCameras = true
                }
                self.evalSceneTemplate()
            }
            
            case "updateScenePoints": do { self.addPointsToScene() }
            case "updateSceneCams": do { self.addCamerasToScene()  }
            case "calculateModel": do { self.calculateModel() }
            case "exportModel": do {
                DispatchQueue.main.async {
                    self.calculatingModel = false
                    self.exportingModel = true
                }
                self.exportModel()
            }
            
            case "loadModel": do { self.downloadAndLoadModel() }
            default: do { return }
        }
        
        if(myCmd == nil){
            self.tasks.remove(task)
            self.taskCmd.removeValue(forKey: task)
        }
    }
    
    func closeConn(){
        DispatchQueue.main.async {
            self.refreshProjectList()
            self.currentProject = project_info()
            self.evaluatingProjectInfo = false
            self.evaluatingPoints = false
            self.evaluatingCameras = false
            self.aligningImages = false
            self.mediaUploading = false
            self.calculatingModel = false
            self.exportingModel = false
            self.projectCmds = false
            self.projectFirstLoad = false
            self.stat_uploaded = 0
            self.stat_total = 0
            self.currentScene = 0
            self.httpHelper = HTTPHelper.shared
            self.taskCmd = [String : String]()
            self.observerActive = false
            self.hasLoadedNModel = false
            self.hasLoadedPModel = false
            
            RCNodeScene.sharedAlignment.clearScene()
            RCNodeScene.sharedPreviewModel.clearScene()
            RCNodeScene.sharedModel.clearScene()
        }
    }
    
    func refreshProjectList(){
        self.httpHelper.httpPattern(url: "/node/projects", tol: 5, sessionID: nil) { (httpData, data, response, valid) in
            if(valid) {
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
                }
            }
        }
    }
    
    func changeProject(name : String){
        if(name == self.currentProject.name) { return }
        
        self.projectCmds = true
        //Close project
        if(self.currentProject.loaded){
            self.closeProject(){ valid in
                if(valid){
                    self.projectCmds = true
                    self.openOrCreate(name: name)
                }
            }
        } else { self.openOrCreate(name: name) }
    }
    
    func openOrCreate(name: String){
        //Create project
        if(!self.projectList.contains(name)){
            self.httpHelper.httpPattern(url: "/project/create", tol: 10, sessionID: nil) { (httpData, data, response, valid) in
                DispatchQueue.main.async {
                    if(!valid) { self.projectCmds = false }
                    else {
                        var encName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                        if(encName == ""){
                            encName = "cr_fly_\(String(describing: (DateFormatter().string(from: Date()))))"
                        }
                        self.currentProject.loaded = true
                        self.currentProject.name = encName!
                        self.currentProject.sessionID = response!.value(forHTTPHeaderField: "Session")!
                        self.saveProject(){ valid in
                            DispatchQueue.main.async {
                                if(valid){
                                    self.projectList.removeFirst()
                                    self.evaluatingProjectInfo = true
                                    self.createTemplateFiles()
                                }
                                self.projectCmds = false
                            }
                        }
                    }
                }
            }
        } else {
            if(self.projectGUIDs[name] == nil){
                GlobalAlertHelper.shared.showError(msg: "No guid for project \(name)")
            } else {
                //Open project
                self.httpHelper.httpPattern(url: "/project/open?guid=\(self.projectGUIDs[name]!)", tol: 10, sessionID: nil) { (httpData, data, response, valid) in
                    if(valid) {
                        DispatchQueue.main.async {
                            self.projectList.removeFirst()
                            self.currentProject.loaded = true
                            self.currentProject.name = name
                            self.currentProject.sessionID = self.projectGUIDs[name]!
                            
                            self.evaluatingProjectInfo = true
                            self.createTemplateFiles()
                            self.projectCmds = false
                        }
                    }
                }
            }
        }
    }
    
    func saveProject(completionHandler: @escaping (Bool) -> Void){
        DispatchQueue.main.async { self.projectCmds = true }
        self.httpHelper.httpPattern(url: "/project/save?name=\(self.currentProject.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)", tol: 10, sessionID: self.currentProject.sessionID) { (httpData, data, response, valid) in
            completionHandler(valid)
            DispatchQueue.main.async { self.projectCmds = false }
        }
    }
    
    func closeProject(completionHandler: @escaping (Bool) -> Void){
        RCNodeScene.sharedAlignment.clearScene()
        RCNodeScene.sharedPreviewModel.clearScene()
        RCNodeScene.sharedModel.clearScene()
        DispatchQueue.main.async {
            self.currentScene = 0
            self.projectCmds = true
        }
        self.httpHelper.httpPattern(url: "/project/close", tol: 10, sessionID: self.currentProject.sessionID) { (httpData, data, response, valid) in
            DispatchQueue.main.async {
                if(valid) { self.closeConn() }
                completionHandler(valid)
                self.projectCmds = false
            }
        }
    }
    
    func deleteProject(){
        DispatchQueue.main.async { self.projectCmds = true }
        
        let guid = self.currentProject.sessionID
        self.closeProject(){ valid in
            DispatchQueue.main.async {
                if(!valid){ self.projectCmds = false }
                else {
                    self.projectCmds = true
                    self.httpHelper.httpPattern(url: "/project/delete?guid=\(guid)", tol: 10, sessionID: nil){
                        (httpData, data, response, valid) in
                        DispatchQueue.main.async {
                            if(valid) { self.refreshProjectList() }
                            self.projectCmds = false
                        }
                    }
                }
            }
        }
    }
    
    func createTemplateFiles(){
        self.createProjectTemplateFile(){ error in
            if(error != nil){
                GlobalAlertHelper.shared.createAlert(title: "Error creating template", msg: "Reopen project or contact dev, error : \(error!)")
            } else {
                self.createPointTemplateFile(){ error in
                    if(error != nil){
                        GlobalAlertHelper.shared.createAlert(title: "Error creating template", msg: "Reopen project or contact dev, error : \(error!)")
                    } else {
                        self.createCameraTemplateFile(){ error in
                            if(error != nil){
                                GlobalAlertHelper.shared.createAlert(title: "Error creating template", msg: "Reopen project or contact dev, error : \(error!)")
                            } else {
                                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                                    self.evalInfoTemplate()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func createProjectTemplateFile(completionHandler: @escaping (String?) -> Void){
        let stringData = "$Using(\"CapturingReality.Report.ProjectInformationExportFunctionSet\")$Using(\"CapturingReality.Report.SfmExportFunctionSet\"){$ExportProjectInfo(\"name\":\"$(projectName)\",\"componentCount\":$(componentCount),\"imageCount\":$(imageCount),\"projectId\":\"$(projectGUID)\" $If(componentCount>0,,\"sfm\":{\"id\": \"$(actualComponentGUID)\",\"cameraCount\": $(cameraCount),\"pointCount\": $(pointCount),\"measurementCount\": $(measurementCount), \"displayScale\":$(displayScale)})) }"
        self.httpHelper.createProjectTemplateFile(name: "crfly-info", data: stringData, sessionID: self.currentProject.sessionID){ error in
            completionHandler(error)
        }
    }
    
    func createPointTemplateFile(completionHandler: @escaping (String?) -> Void){
        let stringData = "$Using(\"CapturingReality.Report.SfmExportFunctionSet\")$ExportPointsEx(\"weak|ill|outlier\",0,999999,$(aX:.4),$(aY:.4),$(aZ:.4),$(r:c),$(g:c),$(b:c),)$Strip(1)"
        
        self.httpHelper.createProjectTemplateFile(name: "crfly-pts", data: stringData, sessionID: self.currentProject.sessionID){ error in
            completionHandler(error)
        }
    }
    
    func createCameraTemplateFile(completionHandler: @escaping (String?) -> Void){
        let stringData = "$Using(\"CapturingReality.Report.SfmExportFunctionSet\")$ExportCameras($(aYaw:.4),$(aPitch:.4),$(aRoll:.4),$(aX:.4),$(aY:.4),$(aZ:.4),)$Strip(1)"
        
        self.httpHelper.createProjectTemplateFile(name: "crfly-cams", data: stringData, sessionID: self.currentProject.sessionID){ error in
            completionHandler(error)
        }
    }
    
    func evalInfoTemplate(){
        DispatchQueue.main.async { self.evaluatingProjectInfo = true }
        self.httpHelper.httpPattern(url: "/project/command?name=exportReport&param1=crfly-info-out.json&param2=crfly-info.tpl", tol: 10, sessionID: self.currentProject.sessionID){ (httpData, data, response, valid) in
            DispatchQueue.main.async {
                if(!valid) { self.evaluatingProjectInfo = false }
                else {
                    self.mediaUploading = false
                    if(!self.projectFirstLoad){
                        self.doTask(task: "", myCmd: "updateScene")
                        
                        let fileUrl = URL(fileURLWithPath: self.libraryURL.relativePath).appendingPathComponent("normal-model.obj")
                        if(FileManager.default.fileExists(atPath: fileUrl.relativePath)){
                            self.hasLoadedNModel = true
                            RCNodeScene.sharedModel.addModel(path: fileUrl)
                        }
                            
                        self.projectFirstLoad = true
                    } else {
                        self.aligningImages = true
                        self.alignImages()
                    }
                    self.addTaskObserver(taskUUID: data!["taskID"] as! String, command: "updateProjectInfo")
                }
            }
        }
    }
    
    func evalSceneTemplate(){
        DispatchQueue.main.async {
            self.evaluatingPoints = true
            self.evaluatingCameras = true
        }
        self.httpHelper.httpPattern(url: "/project/command?name=exportReport&param1=crfly-pts-out.json&param2=crfly-pts.tpl", tol: 10, sessionID: self.currentProject.sessionID){ (httpData, data, response, valid) in
            DispatchQueue.main.async {
                if(!valid){ self.evaluatingPoints = false; self.evaluatingCameras = false; }
                else {
                    self.addTaskObserver(taskUUID: data!["taskID"] as! String, command: "updateScenePoints")
                    
                    self.httpHelper.httpPattern(url: "/project/command?name=exportReport&param1=crfly-cams-out.json&param2=crfly-cams.tpl", tol: 10, sessionID: self.currentProject.sessionID){ (httpData2, data2, response2, valid2) in
                        if(!valid) { self.evaluatingCameras = false }
                        else {
                            self.addTaskObserver(taskUUID: data2!["taskID"] as! String, command: "updateSceneCams")
                        }
                    }
                }
            }
        }
    }
    
    func updateProjectInfo(){
        self.httpHelper.httpPattern(url: "/project/download?name=crfly-info-out.json&folder=output", tol: 10, sessionID: self.currentProject.sessionID){ (httpData, data, response, valid) in
            DispatchQueue.main.async {
                if(!valid) { self.evaluatingProjectInfo = false }
                else {
                    self.currentProject.imageCnt = data!["imageCount"] as! Int
                    self.currentProject.componentCnt = data!["componentCount"] as! Int
                    if(self.currentProject.componentCnt > 0){
                        let sfmData = data!["sfm"] as! [String: Any]
                            
                        self.currentProject.sfmID = sfmData["id"] as! String
                        self.currentProject.cameraCnt = sfmData["cameraCount"] as! Int
                        self.currentProject.pointCnt = sfmData["pointCount"] as! Int
                        self.currentProject.measurementCnt = sfmData["measurementCount"] as! Int
                        self.currentProject.displayScale = sfmData["displayScale"] as! Int
                    }
                    self.httpHelper.httpPattern(url: "/project/list?folder=data", tol: 10, sessionID: self.currentProject.sessionID){ (httpData2, data2, response2, valid2) in
                        DispatchQueue.main.async {
                            if(valid) {
                                self.currentProject.fileList.removeAll()
                                let jsonArray = self.httpHelper.parseJsonData1D(data: httpData2)
                                if(!jsonArray!.isEmpty){
                                    for jsonData in jsonArray! {
                                        self.currentProject.fileList.insert(jsonData)
                                    }
                                }
                                self.doTask(task: "", myCmd: "updateScene")
                            }
                            self.evaluatingProjectInfo = false
                        }
                    }
                }
            }
        }
    }
    
    func addPointsToScene(){
        self.httpHelper.httpPattern(url: "/project/download?name=crfly-pts-out.json&folder=output", tol: 10, sessionID: self.currentProject.sessionID){ (httpData, data, response, valid) in
            DispatchQueue.main.async {
                if(valid) {
                    if(self.currentProject.pointCnt > 0){
                        let pts_data = String(data: httpData!, encoding: .utf8)!
                        let components = pts_data.components(separatedBy: ",")
                        for i in stride(from: 0, through: components.count-1, by: 6) {
                            let dS = Float(self.currentProject.displayScale)
                            RCNodeScene.sharedAlignment.addPointToScene(x: Float(components[i])!, y: Float(components[i+1])!, z: Float(components[i+2])!, r: components[i+3], g: components[i+4], b: components[i+5], scale: dS)
                        }
                    }
                }
                self.evaluatingPoints = false
            }
        }
    }
    
    func addCamerasToScene(){
        self.httpHelper.httpPattern(url: "/project/download?name=crfly-cams-out.json&folder=output", tol: 10, sessionID: self.currentProject.sessionID){ (httpData, data, response, valid) in
            DispatchQueue.main.async {
                if(valid) {
                    if(self.currentProject.cameraCnt > 0){
                        let pts_data = String(data: httpData!, encoding: .utf8)!
                        let components = pts_data.components(separatedBy: ",")
                        for i in stride(from: 0, through: components.count-1, by: 6) {
                            let dS = Float(self.currentProject.displayScale)
                            RCNodeScene.sharedAlignment.addCameraToScene(yaw: Float(components[i])!, pitch: Float(components[i+1])!, roll: Float(components[i+2])!, x: Float(components[i+3])!, y: Float(components[i+4])!, z: Float(components[i+5])!, scale: dS)
                        }
                    }
                }
                self.evaluatingCameras = false
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
                self.addTaskObserver(taskUUID: jsonData!["taskID"] as! String, command: "addImage")
                completionHandler(nil)
            }
            
        }.resume()
    }
    
    func alignImages() {
        DispatchQueue.main.async { self.aligningImages = true }
        RCNodeScene.sharedAlignment.clearScene()
        self.httpHelper.httpPattern(url: "/project/command?name=align", tol: 10, sessionID: self.currentProject.sessionID){ (httpData, data, response, valid) in
            DispatchQueue.main.async {
                if(!valid) { self.aligningImages = false }
                else { self.addTaskObserver(taskUUID: data!["taskID"] as! String, command: "updateScene") }
            }
        }
    }
    
    func prepareModelToExport() {
        self.calculatingModel = true
        self.httpHelper.httpPattern(url: "/project/command?name=selectTrianglesInsideReconReg", tol: 10, sessionID: self.currentProject.sessionID){ (httpData, data, response, valid) in
            DispatchQueue.main.async {
                if(!valid) { self.calculatingModel = false }
                else { self.addTaskObserver(taskUUID: data!["taskID"] as! String, command: "calculateModel") }
            }
        }
    }
    
    func calculateModel() {
        self.httpHelper.httpPattern(url: "/project/command?name=calculateNormalModel", tol: 10, sessionID: self.currentProject.sessionID){ (httpData, data, response, valid) in
            DispatchQueue.main.async {
                if(!valid){ self.calculatingModel = false }
                else { self.addTaskObserver(taskUUID: data!["taskID"] as! String, command: "exportModel") }
            }
        }
    }
    
    func exportModel() {
        self.httpHelper.httpPattern(url: "/project/command?name=exportSelectedModel&param1=normal-model.obj", tol: 10, sessionID: self.currentProject.sessionID){ (httpData, data, response, valid) in
            DispatchQueue.main.async {
                if(!valid){ self.calculatingModel = false }
                else { self.addTaskObserver(taskUUID: data!["taskID"] as! String, command: "loadModel") }
            }
        }
    }
    
    func downloadAndLoadModel() {
        let request = self.httpHelper.prepareDownloadRequest(url: "/project/download?name=normal-model.obj&folder=output", sessionID: self.currentProject.sessionID)
        
        URLSession.shared.downloadTask(with: request) { (tempLocalUrl, response, error) in
            DispatchQueue.main.async {
                if(error != nil || tempLocalUrl == nil || ((response as! HTTPURLResponse).statusCode / 100) != 2){
                    GlobalAlertHelper.shared.showError(msg: "Cannot download model to device!")
                }
                
                let fileUrl = URL(fileURLWithPath: self.libraryURL.relativePath).appendingPathComponent("normal-model.obj")
                do {
                    if(FileManager.default.fileExists(atPath: fileUrl.relativePath)){
                        try FileManager.default.removeItem(at: fileUrl)
                    }
                    try FileManager.default.copyItem(at: tempLocalUrl!, to: fileUrl)
                } catch { GlobalAlertHelper.shared.showError(msg: "Cannot download model to device!") }
                self.hasLoadedNModel = true
                RCNodeScene.sharedModel.addModel(path: fileUrl)
                self.exportingModel = false
            }
        }.resume()
    }
}
