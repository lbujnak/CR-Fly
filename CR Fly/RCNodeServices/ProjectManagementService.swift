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
    
    @Published var currentScene = 0  //1-preview,2-normal,3-colorized
    @Published var mediaUploading = false
    @Published var stat_uploaded = 0
    @Published var stat_total = 0
    
    @Published var hasLoadedModel = [modelType]()
    
    @Published var savable = false
    private var projectGUIDs = [String : String]()
    private var httpHelper = HTTPHelper.shared
    private var taskCmd = [String : String]()
    private var libraryURL : URL = URL(filePath: NSHomeDirectory())
    
    enum modelType { case preview, normal, colorized }
    
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
        var projectID: String = ""
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
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)){
                    self.checkTasks()
                }
            }
        }
    }
    
    private var tasks = Set<String>() {
        didSet{
            if(!self.observerActive) {
                if(tasks.count > 0) { DispatchQueue.main.async { self.observerActive = true }}
            }
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
        
        if(self.tasks.count == 0) {
            DispatchQueue.main.async { self.observerActive = false }
            return
        }
        
        self.httpHelper.httpPattern(url: "/project/tasks?taskIDs=\(joinedString)", tol: 60, sessionID: self.currentProject.sessionID) {
            (httpData, data, response, valid) in
            if(!valid) { self.observerActive = false }
            else{
                if(!self.observerActive){ return }
                
                let jsonArray = self.httpHelper.parseJsonData3D(data: httpData)
                if(jsonArray != nil && !jsonArray!.isEmpty){
                    for jsonData in jsonArray! {
                        //print("\(jsonData["state"]) - \(jsonData["taskID"]) (\(self.taskCmd[jsonData["taskID"] as! String]) ")
                        if(jsonData["state"] as! String == "finished" && self.tasks.contains(jsonData["taskID"] as! String)){
                            self.doTask(task: jsonData["taskID"] as! String, myCmd: nil)
                        } else if(jsonData["state"] as! String == "failed"){
                            //TODO:: pri refraktorizacii -> povypinat premenne, kt. informuju o vykon. akcii
                            GlobalAlertHelper.shared.createAlert(title: "Task Error", msg: "Error executing task: \(String(describing: jsonData["taskID"]!)), error: \(String(describing: jsonData["errorMessage"]!))")
                            self.tasks.remove((jsonData["taskID"] as! String))
                            self.taskCmd.removeValue(forKey: (jsonData["taskID"] as! String))
                        }
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)){ self.checkTasks() }
            }
        }
    }
    
    func doTask(task: String, myCmd : String?){
        var cmd : String
        if(myCmd == nil){
            if(self.taskCmd[task] == nil) { return }
            cmd = self.taskCmd[task]!
        } else { cmd = myCmd! }
        switch cmd {
            case "imageAdded": do {
                DispatchQueue.main.async {
                    self.stat_uploaded += 1
                    if(self.stat_uploaded == self.stat_total) {
                        self.mediaUploading = false
                        self.alignImages()
                    }
                }
            }
            
            case "selectReconRegPreview": do { self.selectReconReg(type: modelType.preview) }
            case "selectReconRegNormal": do { self.selectReconReg(type: modelType.normal) }
            case "selectReconRegColorized": do { self.selectReconReg(type: modelType.colorized) }
            
            case "evalInfoTemplate": do { self.evalInfoTemplate() }
            case "updateProjectInfo": do { self.updateProjectInfo() }
            case "updateScene": do { self.evalSceneTemplate() }
            case "updateScenePoints": do { self.addPointsToScene() }
            case "updateSceneCams": do { self.addCamerasToScene()  }
            
            case "calculateModelPreview": do { self.calculateModel(type: modelType.preview) }
            case "calculateModelNormal": do { self.calculateModel(type: modelType.normal) }
            case "calculateModelColorized": do { self.calculateModel(type: modelType.colorized) }
            
            case "exportModelPreview": do { self.exportModel(type: modelType.preview) }
            case "exportModelNormal": do { self.exportModel(type: modelType.normal) }
            case "exportModelColorized": do { self.exportModel(type: modelType.colorized) }
            
            case "loadModelPreview": do { self.downloadAndLoadModel(type: modelType.preview) }
            case "loadModelNormal": do { self.downloadAndLoadModel(type: modelType.normal) }
            case "loadModelColorized": do { self.downloadAndLoadModel(type: modelType.colorized) }
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
            self.httpHelper.setConnected(c: false)
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
            self.hasLoadedModel.removeAll()
            
            RCNodeScene.sharedAlignment.clearScene()
            RCNodeScene.sharedModels[modelType.preview]!.clearScene()
            RCNodeScene.sharedModels[modelType.normal]!.clearScene()
            RCNodeScene.sharedModels[modelType.colorized]!.clearScene()
        }
    }
    
    func refreshProjectList(){
        self.httpHelper.httpPattern(url: "/node/projects", tol: 60, sessionID: nil) { (httpData, data, response, valid) in
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
                DispatchQueue.main.async {
                    if(valid){
                        self.projectCmds = true
                        self.openOrCreate(name: name)
                    }
                }
            }
        } else { self.openOrCreate(name: name) }
    }
    
    func openOrCreate(name: String){
        //Create project
        if(!self.projectList.contains(name)){
            self.httpHelper.httpPattern(url: "/project/create", tol: 60, sessionID: nil) { (httpData, data, response, valid) in
                DispatchQueue.main.async {
                    if(!valid) { self.projectCmds = false }
                    else {
                        var encName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                        if(encName == ""){
                            encName = "cr_fly_\(String(describing: Date().timeIntervalSince1970))"
                            self.currentProject.name = encName!
                        } else { self.currentProject.name = name }
                        
                        self.currentProject.loaded = true
                        self.httpHelper.setConnected(c: true)
                        self.currentProject.sessionID = response!.value(forHTTPHeaderField: "Session")!
                        self.currentProject.projectID = response!.value(forHTTPHeaderField: "Session")!
                        self.saveProject(){ valid in
                            DispatchQueue.main.async {
                                if(valid){
                                    self.projectList.removeFirst()
                                    self.evaluatingProjectInfo = true
                                    self.createTemplateFiles()
                                    self.refreshProjectList()
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
                self.httpHelper.httpPattern(url: "/project/open?guid=\(self.projectGUIDs[name]!)", tol: 60, sessionID: nil) { (httpData, data, response, valid) in
                    DispatchQueue.main.async {
                        if(valid) {
                            self.projectList.removeFirst()
                            self.currentProject.loaded = true
                            self.httpHelper.setConnected(c: true)
                            self.currentProject.name = name
                            self.currentProject.sessionID = response?.allHeaderFields["Session"] as! String
                            self.currentProject.projectID = response!.value(forHTTPHeaderField: "Session")!
                            
                            self.evaluatingProjectInfo = true
                            self.createTemplateFiles()
                        }
                        self.projectCmds = false
                    }
                }
            }
        }
    }
    
    func saveProject(completionHandler: @escaping (Bool) -> Void){
        DispatchQueue.main.async { self.projectCmds = true }
        self.httpHelper.httpPattern(url: "/project/save?name=\(self.currentProject.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)", tol: 60, sessionID: self.currentProject.sessionID) { (httpData, data, response, valid) in
            completionHandler(valid)
            DispatchQueue.main.async { self.projectCmds = false }
        }
    }
    
    func closeProject(completionHandler: @escaping (Bool) -> Void){
        DispatchQueue.main.async {
            self.currentScene = 0
            self.projectCmds = true
        }
        RCNodeScene.sharedModels[modelType.preview]!.clearScene()
        RCNodeScene.sharedModels[modelType.normal]!.clearScene()
        RCNodeScene.sharedModels[modelType.colorized]!.clearScene()
        self.httpHelper.httpPattern(url: "/project/close", tol: 60, sessionID: self.currentProject.sessionID) { (httpData, data, response, valid) in
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
                    self.httpHelper.httpPattern(url: "/project/delete?guid=\(guid)", tol: 60, sessionID: nil){
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
        let stringData = "$Using(\"CapturingReality.Report.SfmExportFunctionSet\")$ExportCameras($(invYaw:.4),$(invPitch:.4),$(invRoll:.4),$(aX:.4),$(aY:.4),$(aZ:.4),)$Strip(1)"
        
        self.httpHelper.createProjectTemplateFile(name: "crfly-cams", data: stringData, sessionID: self.currentProject.sessionID){ error in
            completionHandler(error)
        }
    }
    
    func evalInfoTemplate(){
        DispatchQueue.main.async { self.evaluatingProjectInfo = true }
        self.httpHelper.httpPattern(url: "/project/command?name=exportReport&param1=crfly-info(\(self.currentProject.sessionID)).json&param2=crfly-info.tpl", tol: 60, sessionID: self.currentProject.sessionID){ (httpData, data, response, valid) in
            DispatchQueue.main.async {
                if(!valid) { self.evaluatingProjectInfo = false }
                else {
                    if(!self.projectFirstLoad){
                        let preview = URL(fileURLWithPath: self.libraryURL.relativePath).appendingPathComponent("preview-model(\(self.currentProject.sessionID)).obj")
                        let normal = URL(fileURLWithPath: self.libraryURL.relativePath).appendingPathComponent("normal-model(\(self.currentProject.sessionID)).obj")
                        let colorized = URL(fileURLWithPath: self.libraryURL.relativePath).appendingPathComponent("colorized-model(\(self.currentProject.sessionID)).obj")
                        
                        if(FileManager.default.fileExists(atPath: preview.relativePath)){
                            self.hasLoadedModel.append(modelType.preview)
                            RCNodeScene.sharedModels[modelType.preview]!.addModel(path: preview)
                        }
                        
                        if(FileManager.default.fileExists(atPath: normal.relativePath)){
                            self.hasLoadedModel.append(modelType.normal)
                            RCNodeScene.sharedModels[modelType.normal]!.addModel(path: normal)
                        }
                        
                        if(FileManager.default.fileExists(atPath: colorized.relativePath)){
                            self.hasLoadedModel.append(modelType.colorized)
                            RCNodeScene.sharedModels[modelType.colorized]!.addModel(path: colorized)
                        }

                        self.projectFirstLoad = true
                    }
                    
                    self.addTaskObserver(taskUUID: data!["taskID"] as! String, command: "updateProjectInfo")
                }
            }
        }
    }
    
    func evalSceneTemplate(){
        DispatchQueue.main.async {
            self.aligningImages = false
            self.evaluatingPoints = true
            self.evaluatingCameras = true
        }
        self.httpHelper.httpPattern(url: "/project/command?name=exportReport&param1=crfly-pts(\(self.currentProject.sessionID)).json&param2=crfly-pts.tpl", tol: 60, sessionID: self.currentProject.sessionID){ (httpData, data, response, valid) in
            DispatchQueue.main.async {
                if(!valid){ self.evaluatingPoints = false; self.evaluatingCameras = false; }
                else {
                    self.addTaskObserver(taskUUID: data!["taskID"] as! String, command: "updateScenePoints")
                    
                    self.httpHelper.httpPattern(url: "/project/command?name=exportReport&param1=crfly-cams(\(self.currentProject.sessionID)).json&param2=crfly-cams.tpl", tol: 60, sessionID: self.currentProject.sessionID){ (httpData2, data2, response2, valid2) in
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
        self.httpHelper.httpPattern(url: "/project/download?name=crfly-info(\(self.currentProject.sessionID)).json&folder=output", tol: 60, sessionID: self.currentProject.sessionID){ (httpData, data, response, valid) in
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
                    
                    self.httpHelper.httpPattern(url: "/project/list?folder=data", tol: 60, sessionID: self.currentProject.sessionID){ (httpData2, data2, response2, valid2) in
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
        self.httpHelper.httpPattern(url: "/project/download?name=crfly-pts(\(self.currentProject.sessionID)).json&folder=output", tol: 60, sessionID: self.currentProject.sessionID){ (httpData, data, response, valid) in
            DispatchQueue.main.async {
                if(valid) {
                    if(self.currentProject.pointCnt > 0){
                        let pts_data = String(data: httpData!, encoding: .utf8)!
                        let components = pts_data.components(separatedBy: ",")
                        let dS = (RCNodeScene.sharedAlignment.userDisplayScale ? Float(self.currentProject.displayScale) : 1.0)
                        
                        var point_cloud = [PointCloudVertex]()
                        for i in stride(from: 0, through: components.count-1, by: 6) {
                            point_cloud.append(PointCloudVertex(x: Float(components[i+1])!*dS, y: Float(components[i+2])!*dS, z: Float(components[i])!*dS, r: (Float(components[i+3])!/255.0), g: (Float(components[i+4])!/255.0), b: (Float(components[i+5])!/255.0)))
                        }
                        RCNodeScene.sharedAlignment.addPointsToScene(cloud: &point_cloud, scale: Float(self.currentProject.displayScale))
                    }
                }
                self.evaluatingPoints = false
            }
        }
    }
    
    func addCamerasToScene(){
        self.httpHelper.httpPattern(url: "/project/download?name=crfly-cams(\(self.currentProject.sessionID)).json&folder=output", tol: 60, sessionID: self.currentProject.sessionID){ (httpData, data, response, valid) in
            DispatchQueue.main.async {
                if(valid) {
                    if(self.currentProject.cameraCnt > 0){
                        let pts_data = String(data: httpData!, encoding: .utf8)!
                        let components = pts_data.components(separatedBy: ",")
                        let dS = (RCNodeScene.sharedAlignment.userDisplayScale ? Float(self.currentProject.displayScale) : 1.0)
                        
                        for i in stride(from: 0, through: components.count-1, by: 6) {
                            RCNodeScene.sharedAlignment.addCameraToScene(yaw: Float(components[i])!, pitch: Float(components[i+1])!, roll: Float(components[i+2])!, x: Float(components[i+3])!*dS, y: Float(components[i+4])!*dS, z: Float(components[i+5])!*dS, scale: dS)
                        }
                    }
                }
                self.evaluatingCameras = false
            }
        }
    }
    
    func sendSingleImage(path : URL, completionHandler: @escaping (String?) -> Void) {
        if(self.currentProject.fileList.contains(path.lastPathComponent)){
            self.stat_uploaded += 1
            if(self.stat_uploaded == self.stat_total){
                self.mediaUploading = false
                self.alignImages()
            }
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
                self.addTaskObserver(taskUUID: jsonData!["taskID"] as! String, command: "imageAdded")
                completionHandler(nil)
            }
        }.resume()
    }
    
    func alignImages() {
        DispatchQueue.main.async { self.aligningImages = true }
        RCNodeScene.sharedAlignment.clearScene()
        self.httpHelper.httpPattern(url: "/project/command?name=align", tol: 60, sessionID: self.currentProject.sessionID){ (httpData, data, response, valid) in
            DispatchQueue.main.async {
                if(!valid) { self.aligningImages = false }
                else { self.addTaskObserver(taskUUID: data!["taskID"] as! String, command: "evalInfoTemplate") }
            }
        }
    }
    
    func getModelFilename(type: modelType, ssid: String) -> String{
        var filename = ""
        switch type {
            case modelType.preview: filename = "preview-model"
            case modelType.normal: filename = "normal-model"
            case modelType.colorized: filename = "colorized-model"
        }
        filename += "(\(ssid))"
        return filename
    }
    
    func prepareModelToExport(type: modelType){
        self.calculatingModel = true
        self.httpHelper.httpPattern(url: "/project/command?name=setReconstructionRegionAuto", tol: 60, sessionID: self.currentProject.sessionID){ (httpData, data, response, valid) in
            DispatchQueue.main.async {
                if(!valid) { self.calculatingModel = false }
                else {
                    switch type {
                        case modelType.preview: self.addTaskObserver(taskUUID: data!["taskID"] as! String, command: "selectReconRegPreview")
                        case modelType.normal: self.addTaskObserver(taskUUID: data!["taskID"] as! String, command: "selectReconRegNormal")
                        case modelType.colorized: self.addTaskObserver(taskUUID: data!["taskID"] as! String, command: "selectReconRegColorized")
                    }
                }
            }
        }
    }
    
    func selectReconReg(type: modelType) {
        DispatchQueue.main.async { self.calculatingModel = true }
        RCNodeScene.sharedModels[type]!.clearScene()
        
        self.httpHelper.httpPattern(url: "/project/command?name=selectTrianglesInsideReconReg", tol: 60, sessionID: self.currentProject.sessionID){ (httpData, data, response, valid) in
            DispatchQueue.main.async {
                if(!valid) { self.calculatingModel = false }
                else {
                    switch type {
                        case modelType.preview: self.addTaskObserver(taskUUID: data!["taskID"] as! String, command: "calculateModelPreview")
                        case modelType.normal: self.addTaskObserver(taskUUID: data!["taskID"] as! String, command: "calculateModelNormal")
                        case modelType.colorized: self.addTaskObserver(taskUUID: data!["taskID"] as! String, command: "calculateModelColorized")
                    }
                }
            }
        }
    }
    
    func calculateModel(type: modelType) {
        var url = ""
        switch type {
            case modelType.preview: url = "calculatePreviewModel"
            case modelType.normal: url = "calculateNormalModel"
            case modelType.colorized: url = "calculateTexture"
        }
        url = "/project/command?name=\(url)"
        
        self.httpHelper.httpPattern(url: url, tol: 60, sessionID: self.currentProject.sessionID){ (httpData, data, response, valid) in
            DispatchQueue.main.async {
                if(!valid){ self.calculatingModel = false }
                else {
                    switch type {
                        case modelType.preview: self.addTaskObserver(taskUUID: data!["taskID"] as! String, command: "exportModelPreview")
                        case modelType.normal: self.addTaskObserver(taskUUID: data!["taskID"] as! String, command: "exportModelNormal")
                        case modelType.colorized: self.addTaskObserver(taskUUID: data!["taskID"] as! String, command: "exportModelColorized")
                    }
                }
            }
        }
    }
    
    func exportModel(type: modelType) {
        DispatchQueue.main.async {
            self.calculatingModel = false
            self.exportingModel = true
        }
        
        let filename = self.getModelFilename(type: type, ssid: self.currentProject.sessionID)
        self.httpHelper.httpPattern(url: "/project/command?name=exportSelectedModel&param1=\(filename).obj", tol: 60, sessionID: self.currentProject.sessionID){ (httpData, data, response, valid) in
            DispatchQueue.main.async {
                if(!valid){ self.calculatingModel = false }
                else {
                    switch type {
                        case modelType.preview: self.addTaskObserver(taskUUID: data!["taskID"] as! String, command: "loadModelPreview")
                        case modelType.normal: self.addTaskObserver(taskUUID: data!["taskID"] as! String, command: "loadModelNormal")
                        case modelType.colorized: self.addTaskObserver(taskUUID: data!["taskID"] as! String, command: "loadModelColorized")
                    }
                }
            }
        }
    }
    
    func downloadAndLoadModel(type : modelType) {
        let filename = self.getModelFilename(type: type, ssid: self.currentProject.sessionID)
        
        //toto robi z 3D modelu nepeknu blbost -> nic neni vidno ;(
        if(type == modelType.colorized){
            let mtlRequest = self.httpHelper.prepareDownloadRequest(url: "/project/download?name=\(filename).mtl&folder=output", sessionID: self.currentProject.sessionID)
            URLSession.shared.downloadTask(with: mtlRequest) { (mtlTempUrl, mtlResponse, mtlError) in
                DispatchQueue.main.async {
                    if(mtlError != nil || mtlTempUrl == nil || ((mtlResponse as! HTTPURLResponse).statusCode / 100) != 2){
                        self.exportingModel = false
                        GlobalAlertHelper.shared.showError(msg: "Cannot download model's .mtl file to device!")
                    } else {
                        let mtlUrl = URL(fileURLWithPath: self.libraryURL.relativePath).appendingPathComponent("\(filename).mtl")
                        do {
                            if(FileManager.default.fileExists(atPath: mtlUrl.relativePath)){ try FileManager.default.removeItem(at: mtlUrl) }
                            try FileManager.default.copyItem(at: mtlTempUrl!, to: mtlUrl)
                        } catch {
                            self.exportingModel = false;
                            GlobalAlertHelper.shared.showError(msg: "Cannot download model's .mtl file to device!")
                            return
                        }
                    }
                }
            }.resume()
            
            let pngRequest = self.httpHelper.prepareDownloadRequest(url: "/project/download?name=\(filename)_u1_v1_diffuse.png&folder=output", sessionID: self.currentProject.sessionID)
            URLSession.shared.downloadTask(with: pngRequest) { (tempUrl, response, error) in
                DispatchQueue.main.async {
                    if(error != nil || tempUrl == nil || ((response as! HTTPURLResponse).statusCode / 100) != 2){
                        self.exportingModel = false
                        GlobalAlertHelper.shared.showError(msg: "Cannot download model's .png file to device!")
                    } else {
                        let pngUrl = URL(fileURLWithPath: self.libraryURL.relativePath).appendingPathComponent("\(filename).mtl")
                        do {
                            if(FileManager.default.fileExists(atPath: pngUrl.relativePath)){ try FileManager.default.removeItem(at: pngUrl) }
                            try FileManager.default.copyItem(at: tempUrl!, to: pngUrl)
                        } catch {
                            self.exportingModel = false;
                            GlobalAlertHelper.shared.showError(msg: "Cannot download model's .mtl file to device!")
                            return
                        }
                    }
                }
            }.resume()
        }
            
        let objRequest = self.httpHelper.prepareDownloadRequest(url: "/project/download?name=\(filename).obj&folder=output", sessionID: self.currentProject.sessionID)
        URLSession.shared.downloadTask(with: objRequest) { (objTempUrl, objResponse, objError) in
            if(objError != nil || objTempUrl == nil || ((objResponse as! HTTPURLResponse).statusCode / 100) != 2){
                GlobalAlertHelper.shared.showError(msg: "Cannot download model's .obj file to device!")
            } else {
                let objUrl = URL(fileURLWithPath: self.libraryURL.relativePath).appendingPathComponent("\(filename).obj")
                do {
                    if(FileManager.default.fileExists(atPath: objUrl.relativePath)){ try FileManager.default.removeItem(at: objUrl) }
                    try FileManager.default.copyItem(at: objTempUrl!, to: objUrl)
                } catch {
                    DispatchQueue.main.async { self.exportingModel = false }
                    GlobalAlertHelper.shared.showError(msg: "Cannot download model's .obj file to device!")
                    return
                }
                DispatchQueue.main.async {
                    if(!self.hasLoadedModel.contains(type)) { self.hasLoadedModel.append(type) }
                    RCNodeScene.sharedModels[type]?.addModel(path: objUrl)
                }
            }
            DispatchQueue.main.async { self.exportingModel = false }
        }.resume()
    }
}
