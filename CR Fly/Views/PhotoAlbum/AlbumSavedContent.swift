import SwiftUI
import DJISDK

struct AlbumSavedContent: View {
    @Binding var filter: MediaFilter
    @Binding var selectMode: Bool
    @Binding var selectedItems : [URL]
    @Binding var scrollOffset: CGFloat
    
    @State var oldScrollValue: CGFloat = 0
    private let columns = [GridItem(.adaptive(minimum: 140),alignment: .center)]
    
    @ObservedObject private var appData = CRFly.shared.appData
    
    var body: some View {
        if(self.appData.djiAlbumMediaSaved.isEmpty || DroneHelper.filterMapEmpty(checkFiles: self.appData.djiAlbumMediaSaved, filter: self.filter)){
            Spacer()
        
            Image(systemName: "photo.fill").foregroundColor(.gray).font(.custom("Photo icon", fixedSize: 80))
            Text("No Photos or Videos").foregroundColor(.gray).padding([.top],20)
            Spacer()
        } else {
            ScrollView() {
                VStack {
                    GeometryReader { geometry in
                        Color.clear.preference(key: ViewOffsetKey.self, value: geometry.frame(in: .global).minY)
                    }.frame(width: 0, height: 0)
                    
                    ForEach(self.appData.djiAlbumMediaSaved.sorted(by: { $0.key > $1.key }), id: \.key) { (date, files) in
                        Section(header:
                                    HStack{
                            Text(date.description.prefix(10)).font(.custom("date", size: 15)).bold().padding(.top, 20.0).foregroundColor(.gray)
                            Spacer()
                        }
                        ){
                            LazyVGrid(columns: columns, spacing: 5) {
                                ForEach(files, id: \.self){ (file) in
                                    if(DroneHelper.fileAcceptFilter(file: file, filter: self.filter)){
                                        self.createPreviewForFile(file: file).id("\(file.lastPathComponent)")
                                    }
                                }
                            }
                        }
                    }
                }.padding([.top],100)
            }.padding([.top],-100).zIndex(1)
            .onPreferenceChange(ViewOffsetKey.self) { value in
                if(self.scrollOffset - (value-self.oldScrollValue) <= 0 ||
                   self.scrollOffset - (value-self.oldScrollValue) > 102) {
                        self.oldScrollValue = value
                        return
                }
                self.scrollOffset -= (value - self.oldScrollValue)
                self.oldScrollValue = value
            }
        }
    }

    
    private func createPreviewForFile(file : URL) -> some View {
        let mediaSelected = self.selectedItems.contains(file)
        return ZStack{
            AsyncImage(url: file) { image in
                image.image?.resizable().frame(minWidth: 140, maxWidth: 140, minHeight: 140, maxHeight: 140).foregroundColor(mediaSelected ? .blue : .white)
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
            }
                
            VStack{
                HStack{
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
                    else{ Image(systemName: "camera.metering.unknown").foregroundColor(.white) }
                        Spacer()
                }
            }
        }.frame(width: 140)
    }
}
