import SwiftUI
import DJISDK

struct AlbumTopBar: View {
    
    @Binding var selectMode: Bool
    @Binding var selectedItems : [DJIMediaFile]
    @Binding var filter: MediaFilter
    
    @ObservedObject var appData = CRFly.shared.appData
    
    var body: some View {
        VStack(spacing: 10){
            HStack(spacing: 30){
                //MARK: TopBar, filter info and buttons
                if(!self.selectMode){
                    Button("←"){
                        //TODO: ExitPlaybackMode command then switch view
                        CRFly.shared.viewController.changeView(type: .mainView)
                    }.foregroundColor(.primary).font(.largeTitle)
                    
                    Spacer()
                    HStack {
                        Image(systemName: "app.connected.to.app.below.fill")
                        Text(self.appData.djiDevice != nil ? DJISDKManager.product()!.model! : "Aircraft Album")
                    }.foregroundColor(Color.primary)
                    
                    Spacer()
                    Image(systemName: "cursorarrow.square").font(Font.system(.title)).onTapGesture {
                        self.selectMode = true
                    }
                }
                else {
                    Spacer()
                    HStack{
                        if(self.selectedItems.count == 0){ Text("Select Items") }
                        else{
                            let total = self.totalFileSize(files: self.selectedItems)
                            if(total <= 1000) {
                                Text("\(self.selectedItems.count) file(s) selected (\(String(format: "%.2f", total)) MB)")
                            } else {
                                Text("\(self.selectedItems.count) file(s) selected (\(String(format: "%.2f", total/1000)) GB)")
                            }
                        }
                    }.padding([.leading],40)
                    
                    Spacer()
                    Image(systemName: "cursorarrow.square.fill").foregroundColor(.blue).font(Font.system(.title)).onTapGesture {
                        self.selectMode = false
                        self.selectedItems.removeAll()
                    }
                }
            }.frame(height: 50).background(Color(UIColor.secondarySystemBackground))
            
            // MARK: Download&Upload informations
            // TODO: do
            if(self.appData.mediaDownloadState != nil){ createDownloadInfo() }
            //if(self.rcProjectManagement.mediaUploading) { createUploadInfo() }
            
            // MARK: Album filter
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
        }
    }
    
    private func totalFileSize(files : Array<DJIMediaFile>) -> Double {
        var total: Int64 = 0
        for obj in files{ total += obj.fileSizeInBytes }
        return Double(total/1000000)
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
