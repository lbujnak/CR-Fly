import SwiftUI
import DJISDK

struct AlbumView: View {
    @State var filter: MediaFilter = .all
    @State var selectMode = false
    @State var selectedItems : [DJIMediaFile] = []
    
    @State private var scrollOffset: CGFloat = 0
    private var droneController = CRFly.shared.droneController
    private let columns = [GridItem(.adaptive(minimum: 140),alignment: .center)]
    @ObservedObject private var appData = CRFly.shared.appData
    
    init() {
        UIScrollView.appearance().bounces = false
    }
    
    var body: some View {
        VStack{
            AlbumTopBar(selectMode: self.$selectMode, selectedItems: self.$selectedItems, filter: self.$filter).zIndex(2).offset(y: -self.scrollOffset)
            
            //MARK: Not connected or empty album
            if(self.appData.djiAlbumMedia.isEmpty && !self.appData.mediaThumbnailFetching){
                Spacer()
            
                Image(systemName: "photo.fill").foregroundColor(.gray).font(.custom("Photo icon", fixedSize: 80))
                Text(self.appData.djiDevConn ? "No Photos or Videos": "No video cache").foregroundColor(.gray).padding([.top],20)
                Spacer()
            } 
            //MARK: (Connected) with non-empty album
            else {
                if(self.appData.djiAlbumMedia.isEmpty && self.appData.mediaThumbnailFetching){
                    Spacer()
                    ProgressView().scaleEffect(x: 2, y: 2, anchor: .center).progressViewStyle(CircularProgressViewStyle(tint: .primary))
                    Spacer()
                } else {
                    ScrollView() {
                        VStack {
                            AlbumMediaList(filter: $filter, selectMode: $selectMode, selectedItems: $selectedItems)
                        }.padding([.top],100).background(GeometryReader { proxy in
                            Color.clear.onChange(of: proxy.frame(in: .global).minY) { oldY,newY in
                                if(self.scrollOffset - (newY-oldY) <= 0 || self.scrollOffset - (newY-oldY) > 102) {
                                    return
                                }
                                self.scrollOffset -= newY-oldY
                            }
                        })
                    }.padding([.top],-100).zIndex(1).onAppear()
                }
            }
            if(self.selectMode){ AlbumBottomBar(selectMode: self.$selectMode, selectedItems: self.$selectedItems) }
        }.onAppear(){ 
            self.scrollOffset = 0
        }.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            self.scrollOffset = 0
        }.onChange(of: self.appData.djiDevConn) { old_state,new_state in
            if(new_state) {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)){
                    CRFly.shared.droneController.pushCommand(command: EnterDroneAlbum())
                }
            } else {
                self.scrollOffset = 0
            }
        }
    }
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
