import SwiftUI
import DJISDK

struct AlbumView: View {
    @State private var filter: MediaFilter = .all
    @State private var savedContentMode = false
    @State private var selectMode = false
    @State private var selectedDroneItems : [DJIMediaFile] = []
    @State private var selectedSavedItems : [URL] = []
    @State private var scrollOffset: CGFloat = 0
    private var droneController = CRFly.shared.droneController
    private let columns = [GridItem(.adaptive(minimum: 140),alignment: .center)]
    @ObservedObject private var appData = CRFly.shared.appData
    
    init() {
        UIScrollView.appearance().bounces = false
    }
    
    var body: some View {
        VStack{
            //MARK: Top bar
            VStack(spacing: 10){
                //Back button, Selection info, Selection button
                HStack(spacing: 30){
                    if(!self.selectMode){
                        Button("←"){
                            //TODO: ExitPlaybackMode command then switch view
                            CRFly.shared.viewController.changeView(type: .mainView)
                        }.foregroundColor(.primary).font(.largeTitle)
                        
                        Spacer()
                        Button {
                            self.savedContentMode = false
                            self.selectedSavedItems.removeAll()
                        } label: {
                            Image(systemName: "app.connected.to.app.below.fill")
                            Text(self.appData.djiDevice != nil ? DJISDKManager.product()!.model! : "Aircraft Album")
                        }.foregroundColor(!self.savedContentMode ? .primary : .secondary).disabled(!self.savedContentMode)
                        
                        Button {
                            self.savedContentMode = true
                            self.selectedDroneItems.removeAll()
                        } label: {
                            Text("Saved")
                        }.foregroundColor(self.savedContentMode ? .primary : .secondary).disabled(self.savedContentMode)
                        
                        Spacer()
                        Image(systemName: "cursorarrow.square").font(Font.system(.title)).onTapGesture {
                            self.selectMode = true
                        }
                    }
                    else {
                        Spacer()
                        HStack{
                            //Drone Content Mode and Saved Content Mode Info
                            if(self.savedContentMode){
                                if(self.selectedSavedItems.count == 0){ Text("Select Items") }
                                else{
                                    self.selectedFilesInfo(files: self.selectedSavedItems)
                                }
                            } else {
                                if(self.selectedDroneItems.count == 0){ Text("Select Items") }
                                else{
                                    self.selectedFilesInfo(files: self.selectedDroneItems)
                                }
                            }
                        }.padding([.leading],40)
                        
                        Spacer()
                        Image(systemName: "cursorarrow.square.fill").foregroundColor(.blue).font(Font.system(.title)).onTapGesture {
                            self.selectMode = false
                            self.selectedDroneItems.removeAll()
                            self.selectedSavedItems.removeAll()
                        }
                    }
                }.frame(height: 50).background(Color(UIColor.secondarySystemBackground))
                
                //Dowload and Upload information - remake
                // TODO: do
                if(self.appData.mediaDownloadState != nil){ createDownloadInfo() }
                //if(self.rcProjectManagement.mediaUploading) { createUploadInfo() }
                
                //Album filter
                HStack(alignment: .center){
                    HStack(alignment: .center, spacing: 100){
                        Button{ self.filter = .all }
                    label: { Text("All").foregroundColor((self.filter == .all ? Color.primary : Color.secondary)) }
                        
                        Button{ self.filter = .photos }
                    label: { Text("Photos").foregroundColor((self.filter == .photos ? Color.primary : Color.secondary)) }
                        
                        Button{ self.filter = .videos }
                    label: { Text("Videos").foregroundColor((self.filter == .videos ? Color.primary : Color.secondary)) }
                    }.padding([.horizontal],100)
                }.frame(height: 40)
                    .background(Color(UIColor.secondarySystemBackground)).cornerRadius(10)
            }.zIndex(2).offset(y: -self.scrollOffset)
            
            //MARK: Content on album
            if(self.savedContentMode) {
                AlbumSavedContent(filter: self.$filter, selectMode: self.$selectMode, selectedItems: self.$selectedSavedItems, scrollOffset: self.$scrollOffset).zIndex(1)
            } else {
                AlbumDroneContent(filter: self.$filter, selectMode: self.$selectMode, selectedItems: self.$selectedDroneItems, scrollOffset: self.$scrollOffset).zIndex(1)
            }
            
            //MARK: Bottom bar
            if(self.selectMode){
                HStack(spacing: 50){
                    let clr_tr_disab : Bool = (self.selectedDroneItems.isEmpty && !self.savedContentMode) || (self.selectedSavedItems.isEmpty && self.savedContentMode)
                    Image(systemName: "trash").foregroundColor(clr_tr_disab ? .secondary : .primary).onTapGesture {
                        // TODO: Command? Nie Command?
                    }.disabled(clr_tr_disab)
                    
                    Spacer()
                    Button("Clear"){
                        self.selectedDroneItems.removeAll()
                        self.selectedSavedItems.removeAll()
                    }.foregroundColor(clr_tr_disab ? .secondary : .primary).disabled(clr_tr_disab)
                    
                    Spacer()
                    Button("Select All"){
                        if(self.savedContentMode) {
                            for (_,files) in self.appData.djiAlbumMediaSaved {
                                for file in files {
                                    self.selectedSavedItems.append(file)
                                }
                            }
                        } else {
                            for (_,files) in self.appData.djiAlbumMedia {
                                for file in files {
                                    self.selectedDroneItems.append(file)
                                }
                            }
                        }
                    }.foregroundColor(.primary)
                    
                    Spacer()
                    if(self.appData.mediaSavable){
                        let dwnldDisabled = self.appData.mediaDownloadState != nil || clr_tr_disab
                        let uploadDisabled = dwnldDisabled || self.appData.mediaUploadState != nil || (self.appData.projectName == nil)
                        
                        if(!self.savedContentMode){
                            Image(systemName: "tray.and.arrow.down").foregroundColor(dwnldDisabled ? .secondary : .primary).onTapGesture {
                                CRFly.shared.droneController.pushCommand(command: DownloadDroneMedia(selectedItems: self.selectedDroneItems))
                                self.selectMode = false
                                self.selectedDroneItems.removeAll()
                            }.disabled(dwnldDisabled)
                        }
                        
                        Image(systemName: "square.and.arrow.up").foregroundColor(uploadDisabled ? .secondary : .primary).onTapGesture {
                            //libController.prepareFilesToUpload(selected: self.selectedItems)
                            //self.selectMode = false
                            //self.selectedItems.removeAll()
                        }.disabled(uploadDisabled)
                    }
                }.frame(height: 40).background(Color(UIColor.secondarySystemBackground).ignoresSafeArea()).foregroundColor(.gray)
            }
        }.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            self.scrollOffset = 0
        }.onChange(of: self.filter) {(_,_) in
            self.scrollOffset = 0
        }
    }
    
    private func selectedFilesInfo(files : [DJIMediaFile]) -> Text {
        var total: Int64 = 0
        for obj in files{ total += obj.fileSizeInBytes }
        return self.generateSelectStatus(totalBytes: Double(total/1000000), fileCount: files.count)
    }
    
    private func selectedFilesInfo(files : [URL]) -> Text {
        var total: Int64 = 0
        for file in files {
            do{
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: file.path)
                if let fileSize = fileAttributes[.size] as? NSNumber {
                    total += fileSize.int64Value
                }
            } catch { continue }
        }
        return self.generateSelectStatus(totalBytes: Double(total/1000000), fileCount: files.count)
    }
    
    private func generateSelectStatus(totalBytes: Double, fileCount: Int) -> Text {
        if(totalBytes <= 1000) {
            return Text("\(fileCount) file(s) selected (\(String(format: "%.2f", totalBytes)) MB)")
        } else {
            return Text("\(fileCount) file(s) selected (\(String(format: "%.2f", totalBytes/1000)) GB)")
        }
    }
    
    private func createDownloadInfo() -> some View {
        VStack(spacing: 0){
            ProgressView(value: Double(self.appData.mediaDownloadState!.downloadedBytes), total: Double(self.appData.mediaDownloadState!.totalBytes)).progressViewStyle(.linear).background(Color(red: 0.100, green: 0.100, blue: 0.100)).ignoresSafeArea()
            
            HStack(spacing: 10){
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaledToFit().padding([.horizontal],10)
                
                let perc = Int(Float(self.appData.mediaDownloadState!.downloadedBytes) / Float(self.appData.mediaDownloadState!.totalBytes)*100)
                Text(String(format: "%d%% Downloading files(%d/%d) %.2fMB/s", perc, self.appData.mediaDownloadState!.downloadedMedia, self.appData.mediaDownloadState!.totalMedia, self.appData.mediaDownloadState!.downloadSpeed)).foregroundColor(.white).font(.caption)
                
                Spacer()
                
                Image(systemName: "xmark").onTapGesture {
                    /*self.libController.mediaDownloadStop() { (error) in
                        if(error != nil){
                            GlobalAlertHelper.shared.createAlert(title: "Stopping download", msg: "There was a problem stopping download: " + error!)
                        }
                    }*/
                }.padding([.horizontal],-40).foregroundColor(.white)
            }.frame(height: 30).ignoresSafeArea().background(Color(red: 0.100, green: 0.100, blue: 0.100))
        }.padding([.vertical],-5)
    }
    /*
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
    */
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct AlbumView_Previews: PreviewProvider {
    static let qrScanner = QRCodeScannerController()
    static var previews: some View {
        AlbumView()
    }
}
