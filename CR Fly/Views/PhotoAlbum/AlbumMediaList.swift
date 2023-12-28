import SwiftUI
import DJISDK

struct AlbumMediaList: View {
    @Binding var filter: MediaFilter
    @Binding var selectMode: Bool
    @Binding var selectedItems: [DJIMediaFile]
    @ObservedObject private var appData = CRFly.shared.appData
    let columns = [GridItem(.adaptive(minimum: 140),alignment: .center)]
    
    var body: some View {
        ForEach(appData.djiAlbumMedia.sorted(by: { $0.key > $1.key }), id: \.key) { (date, files) in
            Section(header:
                HStack{
                    Text(date.description.prefix(10)).font(.custom("date", size: 15)).bold().padding(.top, 20.0).foregroundColor(.gray)
                    Spacer()
                }
            ){
                LazyVGrid(columns: columns, spacing: 5) {
                    ForEach(files, id: \.self){ (file) in
                        if(DroneHelper.fileAcceptFilter(file: file, filter: self.filter)){
                            self.createPreviewForFile(file: file).id("\(file.fileName)")
                        }
                    }
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
                                //TODO: PreviewMedia
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
                        if(DroneHelper.isVideo(file: file)) { Image(systemName: "video.fill").foregroundColor(.white).padding([.leading, .bottom],4).font(.custom("fileType", size: 15)) }
                        else if(DroneHelper.isPhoto(file: file)){ Image(systemName: "photo.fill").foregroundColor(.white).padding([.leading, .bottom],4).font(.custom("fileType", size: 15)) }
                        else if(DroneHelper.isPano(file: file)){ Image(systemName: "pano.fill").foregroundColor(.white).padding([.leading, .bottom],4).font(.custom("fileType", size: 15)) }
                        else{ Image(systemName: "camera.metering.unknown").foregroundColor(.white) }
                        Spacer()
                    }
                }
            }
        }.frame(width: 140)
    }
}
