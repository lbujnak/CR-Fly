import SwiftUI

struct AlbumView: View {
    
    @ObservedObject var appData: ApplicationData
    @ObservedObject var controller: AlbumController
    @ObservedObject var savedAlbumController = CRFly.shared.savedAlbumController
    
    var body: some View {
        VStack {
            HideableTopBar(topBar: {
                //MARK: Top bar
                VStack(spacing: 10){
                    //Back button, Selection info, Selection button
                    HStack(spacing: 30){
                        if(!self.controller.selectMode){
                            Button("←"){
                                self.controller.disappear()
                                CRFly.shared.viewController.changeView(type: .mainView)
                            }.foregroundColor(.primary).font(.largeTitle)
                            
                            Spacer()
                            
                            ForEach([CRFly.shared.droneAlbumController, CRFly.shared.savedAlbumController]){ (controller) in
                                let showing = self.controller.id == controller.id
                                Button {
                                    self.controller.disappear()
                                    CRFly.shared.viewController.addView(type: .albumView, view: AnyView(AlbumView(appData: CRFly.shared.appData, controller: controller)))
                                    CRFly.shared.viewController.changeView(type: .albumView)
                                    self.controller.appear()
                                } label: {
                                    AnyView(controller.getTitle(appData: self.appData))
                                }.foregroundColor(showing ? .primary : .secondary).disabled(showing)
                            }
                            
                            Spacer()
                            Image(systemName: "cursorarrow.square").font(Font.system(.title)).onTapGesture {
                                self.controller.toggleSelectMode()
                            }
                        }
                        else {
                            Spacer()
                            
                            HStack{
                                AnyView(self.controller.getSelectStatus())
                            }.padding([.leading],40)
                            
                            Spacer()
                            Image(systemName: "cursorarrow.square.fill").foregroundColor(.blue).font(Font.system(.title)).onTapGesture {
                                self.controller.toggleSelectMode()
                            }
                        }
                    }.frame(height: 50).background(Color(UIColor.secondarySystemBackground))
                    
                    //Dowload and Upload information
                    AlbumView.createDwnUpInfo(appData: self.appData)
                    
                    //Album filter
                    HStack(alignment: .center){
                        HStack(alignment: .center, spacing: 100){
                            Button{ self.controller.toggleFilter(newFilter: MediaFilter.all) }
                        label: { Text("All").foregroundColor((self.controller.filter == .all ? Color.primary : Color.secondary)) }
                            
                            Button{ self.controller.toggleFilter(newFilter: MediaFilter.photos) }
                        label: { Text("Photos").foregroundColor((self.controller.filter == .photos ? Color.primary : Color.secondary)) }
                            
                            Button{ self.controller.toggleFilter(newFilter: MediaFilter.videos) }
                        label: { Text("Videos").foregroundColor((self.controller.filter == .videos ? Color.primary : Color.secondary)) }
                        }.padding([.horizontal],100)
                    }.frame(height: 40)
                        .background(Color(UIColor.secondarySystemBackground)).cornerRadius(10)
                }
            }, content: {
                if(self.controller.albumEmpty){
                    Spacer()
                    if(self.controller.albumLoading){
                        ProgressView().scaleEffect(x: 2, y: 2, anchor: .center).progressViewStyle(CircularProgressViewStyle(tint: .primary))
                    } else {
                        Image(systemName: "photo.fill").foregroundColor(.gray).font(.custom("Photo icon", fixedSize: 80))
                        Text("No Photos or Videos").foregroundColor(.gray).padding([.top],20)
                    }
                    Spacer()
                } else {
                    AnyView(self.controller.getAlbumContent(appData: self.appData))
                }
            }, scrollable: self.controller.albumEmpty ? false : true, scrollStartAt: self.controller.albumEmpty ? 0 : 100)
            
            //MARK: Bottom bar
            if(self.controller.selectMode){
                HStack(spacing: 50){
                    let emptySelect = self.controller.getSelectCount() == 0
                    let trashDisabled = emptySelect || self.appData.mediaDownloadState != nil || self.appData.mediaUploadState != nil
                    Image(systemName: "trash").foregroundColor(trashDisabled ? .secondary : .primary).onTapGesture {
                        self.controller.trashSelected()
                    }.disabled(trashDisabled)
                    
                    Spacer()
                    Button("Clear"){
                        self.controller.unselectAll()
                    }.foregroundColor(emptySelect ? .secondary : .primary).disabled(emptySelect)
                    
                    Spacer()
                    Button("Select All"){
                        self.controller.selectAll()
                    }.foregroundColor(.primary)
                    
                    Spacer()
                    
                    AnyView(self.controller.getSpecialButtons(appData: self.appData))
                    
                    if(self.savedAlbumController.mediaSavable){
                        let dwnldDisabled = self.savedAlbumController.getSelectCount() == 0
                        let uploadDisabled = dwnldDisabled || (self.appData.projectName == nil)
                        
                        Image(systemName: "square.and.arrow.up").foregroundColor(uploadDisabled ? .secondary : .primary).onTapGesture {
                            self.controller.uploadSelected()
                        }.disabled(uploadDisabled)
                    }
                }.frame(height: 40).background(Color(UIColor.secondarySystemBackground).ignoresSafeArea()).foregroundColor(.gray)
            }
        }.onAppear(perform: self.controller.appear)
    }
    
    public static func generateSelectText(totalBytes: Double, itemCount: Int) -> Text {
        if(totalBytes <= 1000) {
            return Text("\(itemCount) file(s) selected (\(String(format: "%.2f", totalBytes)) MB)")
        } else {
            return Text("\(itemCount) file(s) selected (\(String(format: "%.2f", totalBytes/1000)) GB)")
        }
    }
    
    public static func createDwnUpInfo(appData: ApplicationData) -> some View {
        return VStack{
            if(appData.mediaDownloadState != nil){
                VStack(spacing: 0){
                    ProgressView(value: Double(appData.mediaDownloadState!.downloadedBytes), total: Double(appData.mediaDownloadState!.totalBytes)).progressViewStyle(.linear).background(Color(red: 0.100, green: 0.100, blue: 0.100)).ignoresSafeArea()
                    
                    HStack(spacing: 10){
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaledToFit().padding([.horizontal],10)
                        
                        let perc = Int(Float(appData.mediaDownloadState!.downloadedBytes) / Float(appData.mediaDownloadState!.totalBytes)*100)
                        Text(String(format: "%d%% Downloading files(%d/%d) %.2fMB/s", perc, appData.mediaDownloadState!.downloadedMedia, appData.mediaDownloadState!.totalMedia, appData.mediaDownloadState!.downloadSpeed)).foregroundColor(.white).font(.caption)
                        
                        Spacer()
                        
                        Image(systemName: "xmark").onTapGesture {
                            appData.mediaDownloadState = nil
                        }.padding([.horizontal],-40).foregroundColor(.white)
                    }.frame(height: 30).ignoresSafeArea().background(Color(red: 0.100, green: 0.100, blue: 0.100))
                }.padding([.vertical],-5)
            }
            
            if(appData.mediaUploadState != nil) {
                /*VStack(spacing: 0){
                    ProgressView(value: Double(self.rcProjectManagement.stat_uploaded), total: Double(self.rcProjectManagement.stat_total)).progressViewStyle(.linear).background(Color(red: 0.100, green: 0.100, blue: 0.100)).ignoresSafeArea()
                    
                    HStack(spacing: 10){
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaledToFit().padding([.horizontal],10)
                        
                        Text("Uploading files to CR \(self.rcProjectManagement.stat_uploaded)/\(self.rcProjectManagement.stat_total), Project name: \(self.rcProjectManagement.currentProject.name)").foregroundColor(.white).font(.caption)
                        
                        Spacer()
                        
                        Image(systemName: "xmark").onTapGesture {
                            self.rcProjectManagement.mediaUploading = false
                        }.padding([.horizontal],-40).foregroundColor(.white)
                    }.frame(height: 30).ignoresSafeArea().background(Color(red: 0.100, green: 0.100, blue: 0.100))
                }.padding([.vertical],-5)*/
            }
        }
    }
}

#Preview {
    AlbumView(appData: ApplicationData(), controller: DroneAlbumController())
}
