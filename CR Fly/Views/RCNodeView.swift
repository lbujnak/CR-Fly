import SwiftUI

struct RCNodeView: View {
    
    @ObservedObject private var viewHelper = ViewHelper.shared
    @ObservedObject private var alertHelper = GlobalAlertHelper.shared
    @ObservedObject private var rcNodeComm = RCNodeCommunicationService.shared
    @ObservedObject private var rcPM = RCNodeCommunicationService.shared.projectManagement
    
    @State private var infoBar = false
    @State private var newProjectAlert = false
    @State private var deleteConfirmAlert = false
    
    @State private var newProjectName = ""
    
    private var sPName: Binding<String> {
            Binding<String>(
                get: { self.rcPM.currentProject.name },
                set: { self.rcPM.changeProject(name: $0) }
            )
        }
    
    var body: some View {
        ZStack{
            if(self.rcPM.currentScene == 0){ RCNodeScene.sharedAlignment }
            else if(self.rcPM.currentScene == 1){ RCNodeScene.sharedPreviewModel }
            else if(self.rcPM.currentScene == 2){ RCNodeScene.sharedModel }
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
                    } else if(self.rcPM.mediaUploading || self.rcPM.evaluatingProjectInfo || self.rcPM.evaluatingPoints || self.rcPM.evaluatingCameras || self.rcPM.aligningImages || self.rcPM.calculatingModel || self.rcPM.exportingModel) {
                        HStack(spacing: 10){
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaledToFit().padding([.horizontal],10)
                            
                            if(self.rcPM.mediaUploading){
                                Text("Uploading files to CR \(self.rcPM.stat_uploaded)/\(self.rcPM.stat_total)").foregroundColor(.white).font(.caption)
                            } else if(self.rcPM.evaluatingProjectInfo){
                                Text("Loading project info").foregroundColor(.white).font(.caption)
                            } else if(self.rcPM.aligningImages){
                                Text("Aligning images").foregroundColor(.white).font(.caption)
                            } else if(self.rcPM.evaluatingPoints || self.rcPM.evaluatingCameras){
                                Text("Updating project scene").foregroundColor(.white).font(.caption)
                            } else if(self.rcPM.calculatingModel){
                                Text("Calculating model").foregroundColor(.white).font(.caption)
                            } else if(self.rcPM.exportingModel){
                                Text("Exporting model").foregroundColor(.white).font(.caption)
                            }
                            
                            Spacer()
                        }
                    } else if(!self.rcPM.savable){
                        Text("Problem creating shared directory for 3D models - unable to preview/export.").font(.caption).foregroundColor(Color.red);
                    }
                    Spacer()
                    
                    Image(systemName: "info.circle").foregroundColor(self.infoBar ? Color.gray : Color.white).font(.title2).padding([.horizontal],-40).onTapGesture {
                        self.rcPM.refreshProjectList()
                        self.infoBar.toggle()
                    }
                }
                
                if(self.infoBar){ self.createInfoPanel() }
                Spacer()
                
                if(self.rcPM.currentProject.loaded){ self.createBottomBar() }
            }
            
            if(self.rcPM.projectCmds){
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
                            self.rcPM.refreshProjectList()
                        }.disabled(self.rcNodeComm.connectionLost)
                    }
                    
                    Text("ImageCount: \(self.rcPM.evaluatingProjectInfo ? "..." : String(self.rcPM.currentProject.imageCnt))")
                    Text("ComponentCount: \(self.rcPM.evaluatingProjectInfo ? "..." : String(self.rcPM.currentProject.componentCnt))")
                    Text("PointCount: \(self.rcPM.evaluatingProjectInfo ? "..." : String(self.rcPM.currentProject.pointCnt))")
                    Text("CameraCount: \(self.rcPM.evaluatingProjectInfo ? "..." : String(self.rcPM.currentProject.cameraCnt))")
                    
                    Text("SessionID: \((self.rcPM.currentProject.sessionID as NSString).substring(to: min(self.rcPM.currentProject.sessionID.count, 16)))...")
                    
                    let disb = !self.rcPM.currentProject.loaded || self.rcPM.observerActive || self.rcPM.evaluatingProjectInfo || self.rcPM.evaluatingPoints || self.rcPM.evaluatingCameras || self.rcPM.aligningImages
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
                        },message: {
                            Text("Please enter new project's name.")
                        }).background(Color.gray.opacity(self.rcPM.currentProject.loaded ? 0.5 : 1)).cornerRadius(10).disabled(self.rcPM.currentProject.loaded)
                        
                        //Save Project Btn
                        Button(){
                            self.rcPM.saveProject(){ error in }
                        } label: {
                            Text("Save").foregroundColor(disb ? Color.gray : Color.white).padding([.vertical],5).padding([.horizontal],8)
                        }.background(Color.gray.opacity(disb ? 0.5 : 1)).cornerRadius(10).disabled(disb)
                        
                        //Close project Btn
                        Button(){
                            self.rcPM.closeProject(){ error in }
                        } label: {
                            Text("Close").foregroundColor(disb ? Color.gray : Color.white).padding([.vertical],5).padding([.horizontal],8)
                        }.background(Color.gray.opacity(disb ? 0.5 : 1)).cornerRadius(10).disabled(disb)
                        
                        //Delete project Btn
                        Button(){
                            self.deleteConfirmAlert = true
                        } label: {
                            Text("Delete").foregroundColor(disb ? Color.gray : Color.white).padding([.vertical],5).padding([.horizontal],8)
                        }.alert("Connect", isPresented: self.$deleteConfirmAlert, actions: {
                            Button("Delete") { self.rcPM.deleteProject() }
                            Button("Cancel") {}
                        },message: {
                            Text("This action cannot be undone. Are you sure about deleting selected project?")
                        }).background(Color.gray.opacity(disb ? 0.5 : 1)).cornerRadius(10).disabled(disb)
                    }
                }.padding([.vertical,.horizontal],10).foregroundColor(.white)
            }.background(Color.gray.opacity(0.3)).cornerRadius(15).padding([.vertical],-20).padding([.horizontal])
        }
    }
    
    private func createBottomBar() -> some View {
        VStack(alignment: .leading,spacing: 0){
            let bclr = Color(red: 0.100, green: 0.100, blue: 0.100)
            let disab = (self.rcPM.currentProject.pointCnt == 0) || !self.rcPM.savable || self.rcPM.calculatingModel || self.rcPM.exportingModel
            HStack(spacing: 0){
                Button(){
                    self.rcPM.currentScene = 0
                } label: {
                    Text("Alignment").foregroundColor(self.rcPM.currentScene == 0 ? Color.white : Color.gray).padding([.vertical],8).padding([.horizontal],15)
                }.background(bclr.opacity(self.rcPM.currentScene == 0 ? 1 : 0.5)).disabled(self.rcPM.currentScene == 0)
                
                Button(){
                    self.rcPM.currentScene = 1
                } label: {
                    Text("Preview Model").foregroundColor(self.rcPM.currentScene == 1 ? Color.white : Color.gray).padding([.vertical],8).padding([.horizontal],15)
                }.background(bclr.opacity(self.rcPM.currentScene == 1 ? 1 : 0.5)).disabled(self.rcPM.currentScene == 1 || disab || true)
                
                Button(){
                    self.rcPM.currentScene = 2
                    if(!self.rcPM.hasLoadedNModel && !disab){
                        self.rcPM.prepareModelToExport()
                    }
                } label: {
                    Text("Normal Model").foregroundColor(self.rcPM.currentScene == 2 ? Color.white : Color.gray).padding([.vertical],8).padding([.horizontal],15)
                }.background(bclr.opacity(self.rcPM.currentScene == 2 ? 1 : 0.5)).disabled(self.rcPM.currentScene == 2 || disab)
            }.background(bclr.opacity(0.5)).ignoresSafeArea()
            HStack{
                Spacer()
            }.frame(height: 10).background(Color(red: 0.100, green: 0.100, blue: 0.100))
        }
    }
}
