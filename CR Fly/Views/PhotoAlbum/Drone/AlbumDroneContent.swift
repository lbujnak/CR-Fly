import SwiftUI
import DJISDK

struct AlbumDroneContent: View {
    @Binding var filter: MediaFilter
    @Binding var selectMode: Bool
    @Binding var selectedItems : [DJIMediaFile]
    @Binding var scrollOffset: CGFloat
    
    @State var oldScrollValue: CGFloat = 0
    private let columns = [GridItem(.adaptive(minimum: 140),alignment: .center)]
    
    @ObservedObject private var appData = CRFly.shared.appData
    
    var body: some View {
        if((self.appData.djiMediaAlbum.isEmpty && !self.appData.mediaAlbumLoading)){
            Spacer()
            Image(systemName: "photo.fill").foregroundColor(.gray).font(.custom("Photo icon", fixedSize: 80))
            Text(self.appData.djiDevConn ? "No Photos or Videos": "No video cache").foregroundColor(.gray).padding([.top],20)
            Spacer()
        }
        //MARK: (Connected) with non-empty album
        else {
            if(self.appData.djiMediaAlbum.isEmpty && self.appData.mediaAlbumLoading){
                Spacer()
                ProgressView().scaleEffect(x: 2, y: 2, anchor: .center).progressViewStyle(CircularProgressViewStyle(tint: .primary))
                Spacer()
            } else {
                ScrollView() {
                    GeometryReader { geometry in
                        Color.clear.preference(key: ViewOffsetKey.self, value: geometry.frame(in: .global).minY)
                    }.frame(width: 0, height: 0)
                    
                    VStack {
                        ForEach(self.appData.djiMediaAlbum.sorted(by: { $0.key > $1.key }), id: \.key) { (date, files) in
                            Section(header:
                                HStack{
                                    Text(date.description.prefix(10)).font(.custom("date", size: 15)).bold().padding(.top, 20.0).foregroundColor(.gray)
                                    Spacer()
                                }
                            ){
                                LazyVGrid(columns: columns, spacing: 5) {
                                    ForEach(files, id: \.self){ (file) in
                                        if(AlbumHelper.fileAcceptFilter(file: file, filter: self.filter)){
                                            self.createPreviewForFile(file: file).id("\(file.fileName)")
                                        }
                                    }
                                }
                            }
                        }
                    }.padding([.top],100)
                }.padding([.top],-100).zIndex(1)
                .onPreferenceChange(ViewOffsetKey.self) { value in
                    var maxVal: CGFloat = 102
                    if(self.appData.mediaDownloadState != nil) { maxVal += 24 }
                    if(self.appData.mediaUploadState != nil) { maxVal += 24 }
                    
                    if(self.scrollOffset - (value-self.oldScrollValue) <= 0 ||
                       self.scrollOffset - (value-self.oldScrollValue) > maxVal) {
                            self.oldScrollValue = value
                            return
                    }
                    self.scrollOffset -= (value - self.oldScrollValue)
                    self.oldScrollValue = value
                }
            }
        }
    }
    
    private func createPreviewForFile(file : DJIMediaFile) -> some View {
        return ZStack{
            if(file.thumbnail != nil) {
                let mediaSelected = self.selectedItems.contains(file)
                Image(uiImage: file.thumbnail!).resizable().frame(width: 140).foregroundColor(mediaSelected ? .blue : .white)
                    .onTapGesture {
                        if(!mediaSelected){
                            if(self.selectMode) { self.selectedItems.append(file) }
                            else {
                                if(AlbumHelper.isPano(file: file) || AlbumHelper.isVideo(file: file) || AlbumHelper.isPhoto(file: file)) {
                                    CRFly.shared.viewController.changeView(view: AnyView(AlbumDronePreview(file: file)), type: .albumMediaPreview)
                                }
                            }
                        } else {
                            self.selectedItems.remove(at: self.selectedItems.firstIndex(of: file)!)
                        }
                    }
                
                VStack{
                    HStack{
                        if(!CRFly.shared.isMediaSaved(file: file)){
                            Image(systemName: "tray.and.arrow.down.fill").foregroundColor(.white).padding([.trailing, .top],4).font(.custom("dwnld", size: 15))
                        } else {
                            Image(systemName: "tray.and.arrow.down.fill").foregroundColor(.blue).padding([.trailing, .top],4).font(.custom("dwnld", size: 15))
                        }
                        
                        /*
                         if(!self.rcProjectManagement.currentProject.fileList.contains(file.fileName)){
                         if(self.libController.isPhoto(file: file) || self.libController.isPano(file: file)){
                         Image(systemName: "square.and.arrow.up.fill").foregroundColor(.white).padding([.trailing, .top],4).font(.custom("dwnld", size: 15))
                         } else {
                         Image(systemName: "square.and.arrow.up.fill").foregroundColor(.red).padding([.trailing, .top],4).font(.custom("dwnld", size: 15))
                         }
                         }*/
                        
                        Spacer()
                        
                        if(self.selectMode){
                            if(mediaSelected) {
                                Image(systemName: "checkmark.square.fill").foregroundColor(.blue).padding([.trailing, .top],4).font(.custom("checkbox", size: 15))
                            }
                            else {
                                Image(systemName: "square").foregroundColor(.white).padding([.trailing, .top],4).font(.custom("checkbox", size: 15))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    HStack{
                        if(AlbumHelper.isVideo(file: file)) { Image(systemName: "video.fill").foregroundColor(.white).padding([.leading, .bottom],4).font(.custom("fileType", size: 15)) }
                        else if(AlbumHelper.isPhoto(file: file)){ Image(systemName: "photo.fill").foregroundColor(.white).padding([.leading, .bottom],4).font(.custom("fileType", size: 15)) }
                        else if(AlbumHelper.isPano(file: file)){ Image(systemName: "pano.fill").foregroundColor(.white).padding([.leading, .bottom],4).font(.custom("fileType", size: 15)) }
                        else{ Image(systemName: "camera.metering.unknown").foregroundColor(.white) }
                        Spacer()
                    }
                }
            }
        }.frame(width: 140)
    }
}
