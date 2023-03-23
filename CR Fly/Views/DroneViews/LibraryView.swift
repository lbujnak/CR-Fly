import SwiftUI
import DJISDK

struct LibraryView: View {
    
    @ObservedObject var djiService = ProductCommunicationService.shared
    @ObservedObject var libController = ProductCommunicationService.shared.libController
    
    @State var selectMode = false
    @State var selectedItems : Set<DJIMediaFile> = []
    let columns = [GridItem(.adaptive(minimum: 140),alignment: .center)]
    
    var body: some View {
        if(self.libController.mediaList.count == 0 || !self.libController.mediaFetched){
            VStack{
                self.createTopBar()
                if(self.libController.mediaList.count == 0){
                    Spacer()
                    Image(systemName: "photo.fill").foregroundColor(.gray).font(.custom("Photo icon", fixedSize: 80))
                    Text("No video cache").foregroundColor(.gray).padding([.top],20)
                    Spacer()
                }
                else if(!self.libController.mediaFetched){
                    Spacer()
                    ProgressView().scaleEffect(x: 4, y: 4, anchor: .center).progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                }
            }.background(Color.black.ignoresSafeArea()).alert(isPresented: GlobalAlertHelper.$shared.active){ Alert(title: GlobalAlertHelper.shared.title, message: GlobalAlertHelper.shared.msg, dismissButton: .cancel()) }
        }
        else{
            HideableTopView(){
                self.createTopBar()
            } content: {
                VStack{
                    self.createPreviewList()
                }.background(Color.black.ignoresSafeArea())
            }.background(Color.black.ignoresSafeArea()).alert(isPresented: GlobalAlertHelper.$shared.active){ Alert(title: GlobalAlertHelper.shared.title, message: GlobalAlertHelper.shared.msg, dismissButton: .cancel()) }
            if(self.selectMode){ self.createBottomBar() }
        }
    }
    
    private func createTopBar() -> some View{
        VStack{
            HStack(spacing: 30){
                if(!self.selectMode){
                    Button("←"){
                        ViewHelper.shared.libMode = false
                        self.libController.mediaFilter = 0
                    }.foregroundColor(.gray).font(.largeTitle)
                    
                    Spacer()
                    if(!self.djiService.connected || DJISDKManager.product()!.model == nil) { Text("Aircraft Album").foregroundColor(.white) }
                    else { Text(DJISDKManager.product()!.model!).foregroundColor(.white) }
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
            
            HStack(alignment: .center){
                HStack(alignment: .center,spacing: 100){
                    Button{ self.libController.mediaFilter = 0 }
                label: {
                    if(self.libController.mediaFilter == 0) { Text("All").foregroundColor(.white) }
                    else { Text("All").foregroundColor(.gray) }
                }
                    
                    Button{ self.libController.mediaFilter = 1 }
                label: {
                    if(self.libController.mediaFilter == 1) { Text("Photos").foregroundColor(.white) }
                    else { Text("Photos").foregroundColor(.gray) }
                }
                    
                    Button{ self.libController.mediaFilter = 2 }
                label: {
                    if(self.libController.mediaFilter == 2) { Text("Videos").foregroundColor(.white) }
                    else { Text("Videos").foregroundColor(.gray) }
                }
                }.padding([.horizontal],100)
            }.frame(height: 50).background(Color(red: 0.168, green: 0.168, blue: 0.168)).cornerRadius(10).foregroundColor(.gray)
        }
    }
    
    private func createBottomBar() -> some View{
        HStack(spacing: 50){
            Image(systemName: "trash").foregroundColor(.white).onTapGesture {
                self.libController.removeFiles(files: self.selectedItems, completionHandler: {(error) in
                    if(error != nil) {
                        GlobalAlertHelper.shared.createAlert(title: "Error", msg: "There was an error during removing selected files: \(error!)")
                    }
                    else{
                        self.selectMode = false
                        self.selectedItems.removeAll()
                    }
                })
            }
            Spacer()
            
            Button("Clear"){ self.selectedItems.removeAll() }.foregroundColor(.white)
            Spacer()
            
            Button("Select All"){
                for obj in self.libController.mediaList{
                    self.selectedItems.insert(obj)
                }
            }.foregroundColor(.white)
            Spacer()
            
            Image(systemName: "square.and.arrow.up").foregroundColor(.white).onTapGesture {
                GlobalAlertHelper.shared.createAlert(title: "In De", msg: "This feature will be available in next version")
            }
        }.frame(height: 40).background(Color(red: 0.168, green: 0.168, blue: 0.168).ignoresSafeArea()).foregroundColor(.gray)
    }
    
    private func createPreviewList() -> some View{
        LazyVGrid(columns: columns, spacing: 5) {
            ForEach(self.libController.mediaSections.reversed(), id: \.self){ (subArray) in
                if(self.subArrayNotEmptyWithFilter(subArray: subArray)){
                    Section(){
                        ForEach(subArray.reversed(), id: \.self){ (file) in
                            if(self.fileAcceptFilter(file: file)){
                                self.createPreviewForFile(file: file)
                            }
                        }
                    } header: {
                        HStack{
                            Text(subArray.first?.timeCreated.prefix(10) ?? "").font(.custom("date", size: 15)).bold().padding(.top, 20.0).foregroundColor(.gray)
                            Spacer()
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
                Image(uiImage: file.thumbnail!) .resizable().frame(width: 145).foregroundColor(.blue)
                    .onTapGesture { self.selectedItems.remove(file) }
            }
            else{
                Image(uiImage: file.thumbnail!) .resizable().frame(width: 145).foregroundColor(.white)
                    .onTapGesture {
                    if(self.selectMode) { self.selectedItems.insert(file) }
                    else {
                        self.libController.mediaLibPicked = file
                        if(self.isVideo(file: file)){
                            self.libController.prepareVideoPreview(file: file)
                        }
                        else if(self.isPano(file: file) || self.isPhoto(file: file)){
                            self.libController.fetchPreviewFor(file: file)
                        }
                    }
                }
            }
            
            VStack{
                if(self.selectMode){
                    HStack{
                        Spacer()
                        if(contains) { Image(systemName: "checkmark.square.fill").foregroundColor(.blue).padding([.trailing, .top],4).font(.custom("checkbox", size: 18)) }
                        else { Image(systemName: "square").foregroundColor(.white).padding([.trailing, .top],4).font(.custom("checkbox", size: 18)) }
                    }
                }
                Spacer()
                HStack{
                    if(self.isVideo(file: file)) { Image(systemName: "video.fill").foregroundColor(.white).padding([.leading, .bottom],4).font(.custom("fileType", size: 15)) }
                    else if(self.isPhoto(file: file)){ Image(systemName: "photo.fill").foregroundColor(.white).padding([.leading, .bottom],4).font(.custom("fileType", size: 15)) }
                    else if(self.isPano(file: file)){ Image(systemName: "pano.fill").foregroundColor(.white).padding([.leading, .bottom],4).font(.custom("fileType", size: 15)) }
                    else{ Image(systemName: "camera.metering.unknown").foregroundColor(.white) }
                    Spacer()
                }
            }
        }
    }
    
    private func subArrayNotEmptyWithFilter(subArray: [DJIMediaFile]) -> Bool{
        for file in subArray {
            if(self.fileAcceptFilter(file: file)) { return true }
        }
        return false
    }
    
    private func fileAcceptFilter(file: DJIMediaFile) ->Bool{
        if(self.libController.mediaFilter == 0 || (self.libController.mediaFilter == 1 && (self.isPano(file: file) || self.isPhoto(file: file)) ) || (self.libController.mediaFilter == 2 && self.isVideo(file: file))){
            return true
        } else { return false}
    }
    
    private func isVideo(file: DJIMediaFile) -> Bool{
        if(file.mediaType == DJIMediaType.MOV || file.mediaType == DJIMediaType.MP4) {
            return true
        } else { return false }
    }
    
    private func isPhoto(file: DJIMediaFile) -> Bool{
        if(file.mediaType == DJIMediaType.JPEG || file.mediaType == DJIMediaType.RAWDNG){
            return true
        } else {
            return false
        }
    }
    
    private func isPano(file: DJIMediaFile) -> Bool{
        if(file.mediaType == DJIMediaType.panorama){
            return true
        } else {
            return false
        }
    }
    
    private func totalFileSize(files : Set<DJIMediaFile>) -> Double{
        var total : Int64 = 0
        
        for obj in files{
            total += obj.fileSizeInBytes
        }
        
        return Double(total/1000000)
    }

}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryView()
    }
}
