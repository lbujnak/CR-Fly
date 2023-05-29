import SwiftUI
import DJISDK

struct LibraryView: View {
    
    @ObservedObject var djiService = ProductCommunicationService.shared
    @ObservedObject var rcProjectManagement = RCNodeCommunicationService.shared.projectManagement
    @ObservedObject var libController = ProductCommunicationService.shared.libController
    @ObservedObject var alertHelper = GlobalAlertHelper.shared
    
    @State var selectMode = false
    @State var selectedItems : Array<DJIMediaFile> = []
    let columns = [GridItem(.adaptive(minimum: 140),alignment: .center)]
    
    var body: some View {
        VStack{
            if(self.libController.mediaList.count == 0 || !self.libController.mediaFetched){
                self.createTopBar()
                //If there is no photo
                Spacer()
                if(self.libController.mediaList.count == 0){
                    Image(systemName: "photo.fill").foregroundColor(.gray).font(.custom("Photo icon", fixedSize: 80))
                    Text("No video cache").foregroundColor(.gray).padding([.top],20)
                }
                
                //If thumbnail is still loading
                else if(!self.libController.mediaFetched){
                    ProgressView().scaleEffect(x: 4, y: 4, anchor: .center).progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Spacer()
            }
            else{
                HideableTopView(){
                    self.createTopBar()
                } content: {
                    VStack{
                        self.createPreviewList()
                    }.background(Color.black.ignoresSafeArea())
                }
                if(self.selectMode){ self.createBottomBar() }
            }
        }.background(Color.black.ignoresSafeArea()).alert(isPresented: self.$alertHelper.active){ Alert(title: self.alertHelper.title, message: self.alertHelper.msg, dismissButton: .cancel()) }
    }
    
    private func createTopBar() -> some View{
        VStack(spacing: 20){
            HStack(spacing: 30){
                if(!self.selectMode){
                    Button("←"){
                        if(!self.libController.mediaFetched){ self.libController.interruptThumbnailDwnld = true }
                        self.libController.stopPlaybackMode(completionHandler: {(error) in
                            if(error != nil){
                                GlobalAlertHelper.shared.createAlert(title: "Error", msg: "Problem exiting libmode: \(String(describing: error)).")
                                return
                            }
                            ViewHelper.shared.libMode = false
                        })
                    }.foregroundColor(.gray).font(.largeTitle)
                    
                    Spacer()
                    if(!self.djiService.connected || DJISDKManager.product()!.model == nil) {
                        Text("Aircraft Album").foregroundColor(.white)
                    } else {
                        Text(DJISDKManager.product()!.model!).foregroundColor(.white)
                    }
                    Spacer()
                    
                    Image(systemName: "cursorarrow.square").font(Font.system(.title)).onTapGesture { self.selectMode = true }
                }
                else {
                    Spacer()
                    
                    if(self.selectedItems.count == 0){ Text("Select items") }
                    else{
                        let total = self.totalFileSize(files: self.selectedItems)
                        if(total > 1000) {
                            Text("\(self.selectedItems.count) file(s) selected (\(String(format: "%.2f", total/1000)) GB)")
                        } else {
                            Text("\(self.selectedItems.count) file(s) selected (\(String(format: "%.2f", total)) MB)")
                        }
                    }
                    Spacer()
                    
                    Image(systemName: "cursorarrow.square.fill").foregroundColor(.blue).font(Font.system(.title)).onTapGesture {
                        self.selectMode = false
                        self.selectedItems.removeAll()
                    }
                }
            }.frame(height: 50).background(Color(red: 0.168, green: 0.168, blue: 0.168).ignoresSafeArea()).foregroundColor(.gray)
            
            if(self.libController.mediaDownloading){ createDownloadInfo() }
            if(self.rcProjectManagement.mediaUploading) { createUploadInfo() }
                
            HStack(alignment: .center){
                HStack(alignment: .center, spacing: 100){
                    Button{ self.libController.mediaFilter = 0 }
                    label: { Text("All").foregroundColor((self.libController.mediaFilter == 0 ? Color.white : Color.gray)) }
                        
                    Button{ self.libController.mediaFilter = 1 }
                    label: { Text("Photos").foregroundColor((self.libController.mediaFilter == 1 ? Color.white : Color.gray)) }
                        
                    Button{ self.libController.mediaFilter = 2 }
                    label: { Text("Videos").foregroundColor((self.libController.mediaFilter == 2 ? Color.white : Color.gray)) }
                }.padding([.horizontal],100)
            }.frame(height: 40).background(Color(red: 0.168, green: 0.168, blue: 0.168)).cornerRadius(10).foregroundColor(.gray)
        }
    }
    
    private func createDownloadInfo() -> some View {
        VStack(spacing: 0){
            ProgressView(value: Double(self.libController.stat_dwnBytes), total: Double(self.libController.stat_totalBytes)).progressViewStyle(.linear).background(Color(red: 0.100, green: 0.100, blue: 0.100)).ignoresSafeArea()
            
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
            }.frame(height: 30).ignoresSafeArea().background(Color(red: 0.100, green: 0.100, blue: 0.100))
        }.padding([.vertical],-5)
    }
    
    private func createUploadInfo() -> some View {
        VStack(spacing: 0){
            ProgressView(value: Double(self.rcProjectManagement.stat_uploaded), total: Double(self.rcProjectManagement.stat_total)).progressViewStyle(.linear).background(Color(red: 0.100, green: 0.100, blue: 0.100)).ignoresSafeArea()
            
            HStack(spacing: 10){
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaledToFit().padding([.horizontal],10)
                
                Text("Uploading files to CR \(self.rcProjectManagement.stat_uploaded)/\(self.rcProjectManagement.stat_total), Project name: \(self.rcProjectManagement.currentProject.name)").foregroundColor(.white).font(.caption)
                
                Spacer()
                
                Image(systemName: "xmark").onTapGesture {
                    self.rcProjectManagement.mediaUploading = false
                }.padding([.horizontal],-40).foregroundColor(.white)
            }.frame(height: 30).ignoresSafeArea().background(Color(red: 0.100, green: 0.100, blue: 0.100))
        }.padding([.vertical],-5)
    }
    
    private func createBottomBar() -> some View{
        HStack(spacing: 50){
            let clr_tr_disab : Bool = (self.selectedItems.count == 0)
            Image(systemName: "trash").foregroundColor(clr_tr_disab ? Color.gray : Color.white).onTapGesture {
                self.libController.removeFiles(files: self.selectedItems, completionHandler: {(error) in
                    if(error != nil) {
                        GlobalAlertHelper.shared.createAlert(title: "Error", msg: "There was an error during removing selected files: \(error!)")
                    } else {
                        self.selectMode = false
                        self.selectedItems.removeAll()
                    }
                })
            }.disabled(clr_tr_disab)
            Spacer()
            
            Button("Clear"){ self.selectedItems.removeAll() }.foregroundColor(clr_tr_disab ? Color.gray : Color.white).disabled(clr_tr_disab)
            Spacer()
            
            Button("Select All"){
                for obj in self.libController.mediaList {
                    self.selectedItems.append(obj)
                }
            }.foregroundColor(.white)
            Spacer()
            
            if(libController.savable){
                let disab : Bool = (self.libController.mediaDownloading || clr_tr_disab)
                Image(systemName: "tray.and.arrow.down").foregroundColor(disab ? Color.gray : Color.white).onTapGesture {
                    self.libController.prepareAndDownload(selected: self.selectedItems)
                    self.selectMode = false
                    self.selectedItems.removeAll()
                }.disabled(disab)
            
                let rcDisab = disab || self.rcProjectManagement.mediaUploading || !self.rcProjectManagement.currentProject.loaded
                Image(systemName: "square.and.arrow.up").foregroundColor(rcDisab ? Color.gray : Color.white).onTapGesture {
                    libController.prepareFilesToUpload(selected: self.selectedItems)
                    self.selectMode = false
                    self.selectedItems.removeAll()
                }.disabled(rcDisab)
            }
        }.frame(height: 40).background(Color(red: 0.168, green: 0.168, blue: 0.168).ignoresSafeArea()).foregroundColor(.gray)
    }
    
    private func createPreviewList() -> some View{
        ForEach(self.libController.mediaSections.reversed(), id: \.self){ (subArray) in
            if(subArrayNotEmptyWithFilter(subArray: subArray)){
                Section(header:
                    HStack{
                        Text(subArray.first?.timeCreated.prefix(10) ?? "").font(.custom("date", size: 15)).bold().padding(.top, 20.0).foregroundColor(.gray)
                        Spacer()
                    }){
                    LazyVGrid(columns: columns, spacing: 5) {
                        ForEach(subArray.reversed(), id: \.self){ (file) in
                            if(self.fileAcceptFilter(file: file)){
                                self.createPreviewForFile(file: file).id("\(file.fileName)")
                            }
                        }
                    }
                } 
            }
        }
    }
    
    
    private func createPreviewForFile(file : DJIMediaFile) -> some View {
        ZStack{
            let contains = self.selectedItems.contains(file)
            if(contains){
                Image(uiImage: file.thumbnail!) .resizable().frame(width: 140).foregroundColor(.blue)
                    .onTapGesture { self.selectedItems.remove(at: self.selectedItems.firstIndex(of: file)!) }
            }
            else{
                Image(uiImage: file.thumbnail!) .resizable().frame(width: 140).foregroundColor(.white).onTapGesture {
                    if(self.selectMode) { self.selectedItems.append(file) }
                    else {
                        self.libController.prepareFileForPreview(file: file)
                        ViewHelper.shared.libModePicked = true
                    }
                }
            }
            
            VStack{
                HStack{
                    if(!self.libController.mediaSaved(file: file)){
                        if(!self.libController.mediaDownloading(file: file)) {
                            Image(systemName: "tray.and.arrow.down.fill").foregroundColor(.white).padding([.trailing, .top],4).font(.custom("dwnld", size: 15))
                        } else {
                            Image(systemName: "tray.and.arrow.down.fill").foregroundColor(.blue).padding([.trailing, .top],4).font(.custom("dwnld", size: 15))
                        }
                    }
                    
                    if(!self.rcProjectManagement.currentProject.fileList.contains(file.fileName)){
                        if(self.libController.isPhoto(file: file) || self.libController.isPano(file: file)){
                            Image(systemName: "square.and.arrow.up.fill").foregroundColor(.white).padding([.trailing, .top],4).font(.custom("dwnld", size: 15))
                        } else {
                            Image(systemName: "square.and.arrow.up.fill").foregroundColor(.red).padding([.trailing, .top],4).font(.custom("dwnld", size: 15))
                        }
                    }
                    Spacer()
                    if(self.selectMode){
                        if(contains) { Image(systemName: "checkmark.square.fill").foregroundColor(.blue).padding([.trailing, .top],4).font(.custom("checkbox", size: 15)) }
                        else { Image(systemName: "square").foregroundColor(.white).padding([.trailing, .top],4).font(.custom("checkbox", size: 15)) }
                    }
                }
                Spacer()
                HStack{
                    if(self.libController.isVideo(file: file)) { Image(systemName: "video.fill").foregroundColor(.white).padding([.leading, .bottom],4).font(.custom("fileType", size: 15)) }
                    else if(self.libController.isPhoto(file: file)){ Image(systemName: "photo.fill").foregroundColor(.white).padding([.leading, .bottom],4).font(.custom("fileType", size: 15)) }
                    else if(self.libController.isPano(file: file)){ Image(systemName: "pano.fill").foregroundColor(.white).padding([.leading, .bottom],4).font(.custom("fileType", size: 15)) }
                    else{ Image(systemName: "camera.metering.unknown").foregroundColor(.white) }
                    Spacer()
                }
            }
        }.frame(width: 140)
    }
    
    private func subArrayNotEmptyWithFilter(subArray: [DJIMediaFile]) -> Bool{
        for file in subArray {
            if(self.fileAcceptFilter(file: file)) { return true }
        }
        return false
    }
    
    private func fileAcceptFilter(file: DJIMediaFile) ->Bool{
        switch(self.libController.mediaFilter){
            case 0: return true
            case 1: return self.libController.isPano(file: file) || self.libController.isPhoto(file: file)
            case 2: return self.libController.isVideo(file: file)
            default: return false
        }
    }
    
    private func totalFileSize(files : Array<DJIMediaFile>) -> Double{
        var total : Int64 = 0
        for obj in files{ total += obj.fileSizeInBytes }
        return Double(total/1000000)
    }

}
