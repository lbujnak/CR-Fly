import SwiftUI

struct RCNodeView: View {
    
    @ObservedObject private var viewHelper = ViewHelper.shared
    @ObservedObject private var alertHelper = GlobalAlertHelper.shared
    @ObservedObject private var rcNodeComm = RCNodeCommunicationService.shared
    @ObservedObject private var rcPM = RCNodeCommunicationService.shared.projectManagement
    
    @State private var infoBar = false
    @State private var newProjectAlert = false
    @State private var projectCmds : Bool = false
    
    @State private var newProjectName = ""
    
    private var sPName: Binding<String> {
            Binding<String>(
                get: { self.rcPM.currentProject.name },
                set: { self.projectCmds = true
                    self.rcPM.changeProject(name: $0){ error in
                        if(error != nil){
                            GlobalAlertHelper.shared.createAlert(title: "Error Selecting Project", msg: "\(error!)")
                        }
                        self.projectCmds = false
                    }
                }
            )
        }
    
    var body: some View {
        ZStack{
            RCNodeScene.shared
            VStack{
                HStack(spacing: 30){
                    Button("←"){
                        self.viewHelper.rcContMode = false
                    }.foregroundColor(.gray).font(.largeTitle)
                    
                    Spacer()
                    if(self.rcNodeComm.connectionLost){
                        Text("Missing connection - not connected to RC node.").font(.caption).foregroundColor(Color.red);
                    } else if(!self.rcPM.currentProject.loaded){
                        Text("Missing project - create or open a new project by clicking on project name.").font(.caption).foregroundColor(Color.red);
                    } else if(self.rcPM.mediaUploading) {
                        HStack(spacing: 10){
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaledToFit().padding([.horizontal],10)
                            
                            Text("Uploading files to CR, Project name: \(self.rcPM.currentProject.name)").foregroundColor(.white).font(.caption)
                            
                            Spacer()
                            
                            Image(systemName: "xmark").onTapGesture {
                                self.rcPM.mediaUploading = false
                            }.padding([.horizontal],-40).foregroundColor(.white)
                        }
                    }
                    Spacer()
                    
                    Image(systemName: "info.circle").foregroundColor(self.infoBar ? Color.gray : Color.white).font(.title2).padding([.horizontal],-40).onTapGesture {
                        self.rcPM.refreshProjectList(){ error in
                            if(error != nil){
                                GlobalAlertHelper.shared.createAlert(title: "Error Refreshing Project List", msg: "\(error!)")
                                return
                            }
                            self.infoBar.toggle()
                        }
                    }
                }
                
                if(self.infoBar){ self.createInfoPanel() }
                Spacer()
            }
            
            if(self.projectCmds){
                Color.gray.opacity(0.7).edgesIgnoringSafeArea(.all)
                ProgressView().scaleEffect(x: 2, y: 2, anchor: .center)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }.background(Color.black.ignoresSafeArea())
            .alert(isPresented: self.$alertHelper.active){ Alert(title: self.alertHelper.title, message: self.alertHelper.msg, dismissButton: .default(Text("OK"))) }
    }
    
    private func createInfoPanel() -> some View {
        HStack(){
            Spacer()
            VStack{
                VStack(alignment: .leading){
                    HStack{
                        Text("Project Name:").bold()
                        Menu(){
                            Picker(selection: self.sPName, label: Text("")){
                                ForEach(0..<self.rcPM.projectList.count, id: \.self){ index in
                                    Text(self.rcPM.projectList[index]).tag(self.rcPM.projectList[index])
                                }
                            }
                        } label: {
                            HStack{
                                Text(self.sPName.wrappedValue).foregroundColor(.white)
                            }.frame(width: 150, height: 20,alignment: .leading)
                        }.frame(width: 150)
                        
                        Image(systemName: "arrow.clockwise").foregroundColor(self.rcNodeComm.connectionLost ? Color.gray : Color.white).onTapGesture {
                            self.rcPM.refreshProjectList(){ error in
                                if(error != nil){
                                    self.alertHelper.createAlert(title: "Project Refresh Error", msg: "\(error!)")
                                }
                            }
                        }.disabled(self.rcNodeComm.connectionLost)
                    }
                    
                    Text("ImageCount: \(self.rcPM.currentProject.imageCnt)")
                    Text("ComponentCount: \(self.rcPM.currentProject.componentCnt)")
                    Text("SessionID: \((self.rcPM.currentProject.sessionID as NSString).substring(to: min(self.rcPM.currentProject.sessionID.count, 16)))...")
                    
                    HStack{
                        //Create Project Btn
                        Button(){
                            self.newProjectAlert = true
                        } label: {
                            Text("New").foregroundColor(self.rcPM.currentProject.loaded ? Color.gray : Color.white).padding([.vertical],5).padding([.horizontal],8)
                        }.alert("Connect", isPresented: self.$newProjectAlert, actions: {
                            TextField("Project Name", text: self.$newProjectName).foregroundColor(.black)
                            Button("Create") {
                                self.sPName.wrappedValue = self.newProjectName
                                self.newProjectName = ""
                            }
                            Button("Cancel"){ self.newProjectName = "" }
                        },message: { Text("Please enter new project's name.") }).background(Color.gray.opacity(self.rcPM.currentProject.loaded ? 0.5 : 1)).cornerRadius(10).disabled(self.rcPM.currentProject.loaded)
                        
                        //Save Project Btn
                        Button(){
                            self.projectCmds = true
                            self.rcPM.saveProject(){ error in
                                if(error != nil){
                                    GlobalAlertHelper.shared.createAlert(title: "Error Saving Project", msg: "\(error!)")
                                    return
                                }
                                self.projectCmds = false
                            }
                        } label: {
                            Text("Save").foregroundColor(self.rcPM.currentProject.loaded ? Color.white : Color.gray).padding([.vertical],5).padding([.horizontal],8)
                        }.background(Color.gray.opacity(self.rcPM.currentProject.loaded ? 1 : 0.5)).cornerRadius(10).disabled(!self.rcPM.currentProject.loaded)
                        
                        //Close project Btn
                        Button(){
                            self.projectCmds = true
                            self.rcPM.closeProject(){ error in
                                if(error != nil){
                                    GlobalAlertHelper.shared.createAlert(title: "Error Closing Project", msg: "\(error!)")
                                }
                                self.projectCmds = false
                            }
                        } label: {
                            Text("Close").foregroundColor(self.rcPM.currentProject.loaded ? Color.white : Color.gray).padding([.vertical],5).padding([.horizontal],8)
                        }.background(Color.gray.opacity(self.rcPM.currentProject.loaded ? 1 : 0.5)).cornerRadius(10).disabled(!self.rcPM.currentProject.loaded)
                        
                        //Status project Btn
                        Button(){
                            //self.rcNodeComm.taskObserver.checkTasks()
                        } label: {
                            Text("Status").foregroundColor(self.rcPM.currentProject.loaded ? Color.white : Color.gray).padding([.vertical],5).padding([.horizontal],8)
                        }.background(Color.gray.opacity(self.rcPM.currentProject.loaded ? 1 : 0.5)).cornerRadius(10).disabled(!self.rcPM.currentProject.loaded)
                    }
                }.padding([.vertical,.horizontal],10).foregroundColor(.white)
            }.background(Color.gray.opacity(0.3))
                .cornerRadius(15).padding([.vertical],-20).padding([.horizontal])
        }
    }
    
    private func createDownloadInfo() -> some View {
        VStack(spacing: 0){
            /*ProgressView(value: Double(self.libController.stat_dwnBytes), total: Double(self.libController.stat_totalBytes)).progressViewStyle(.linear).background(Color(red: 0.100, green: 0.100, blue: 0.100)).ignoresSafeArea()
            
            HStack(spacing: 10){
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaledToFit().padding([.horizontal],10)
                
                let perc = Int(Float(self.libController.stat_dwnBytes) / Float(self.libController.stat_totalBytes)*100)
                Text(String(format: "%d%% Downloading files(%d/%d) %.2fMB/s", perc, self.libController.mediaDownloaded, self.libController.mediaDownloadList.count, self.libController.stat_speed)).foregroundColor(.white).font(.caption)
                
                Spacer()
                
                Image(systemName: "xmark").onTapGesture {
                    self.libController.mediaDownloadStop() { (error) in
                        if(error != nil){
                            GlobalAlertHelper.shared.createAlert(title: "Stopping download", msg: "There was a problem stopping download: " + error!)
                        }
                    }
                }.padding([.horizontal],-40).foregroundColor(.white)
            }.frame(height: 30).ignoresSafeArea().background(Color(red: 0.100, green: 0.100, blue: 0.100))*/
        }
    }
}
