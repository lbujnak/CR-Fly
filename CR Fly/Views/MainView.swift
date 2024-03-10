import SwiftUI

struct MainView: View {
    @ObservedObject var appData: ApplicationData
    @ObservedObject private var locationController = LocationController()
    
    var body: some View {
        ZStack {
            GeometryReader { proxy in
                Image("background").resizable().scaledToFill().frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                }.ignoresSafeArea()
            
            VStack {
                HStack {
                    if(self.locationController.locationAddress == "") {
                        Image(systemName: "location.magnifyingglass").bold()
                        Text("Locating...").bold()
                    } else {
                        Image(systemName: "location.fill").bold()
                        Text(self.locationController.locationAddress).bold()
                    }
                    Spacer()
                }.padding([.top],30)
                
                Spacer()
                HStack(spacing: 40) {
                    Button {
                        CRFly.shared.viewController.displayView(type: .albumView, addToHistory: true)
                        return
                    } label: {
                        Image(systemName: "photo")
                        Text("Photo Album")
                    }
                    
                    Button {
                        //TODO: RealityCapture scene
                        CRFly.shared.viewController.displayView(type: .sceneView, addToHistory: true)
                        return
                    } label: {
                        Image("realitycapture-logo").resizable()
                            .frame(width: 20, height: 20)
                        Text("3D Scene")
                    }
                    
                    Spacer()
                    if(!CRFly.shared.appData.djiDevConn){
                        Button {
                            //TODO: Connection Guide
                            return
                        } label: {
                            Text("Connection Guide").font(.callout)
                        }.padding([.top,.bottom],15).padding([.leading,.trailing],45)
                        .background(RoundedRectangle(cornerRadius: 10).stroke(.white, lineWidth: 2).fill(.black.opacity(0.7)))
                    } else {
                        Button {
                            //TODO: Connection Guide
                            return
                        } label: {
                            Text("Let's FLY").fixedSize().font(.callout)
                        }.padding([.top,.bottom],15).padding([.leading,.trailing],75)
                            .background(RoundedRectangle(cornerRadius: 10).stroke(.white, lineWidth: 2).fill(.blue))
                    }
                }.padding([.bottom],20)
            }.foregroundColor(.white).padding([.leading,.trailing],20)
            //TODO: Onappear stopplayback
        }
    }
}

#Preview {
    MainView(appData: ApplicationData())
}
