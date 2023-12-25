import SwiftUI

struct MainView: View {
    
    @State private var bridgeConnAlert = false
    @State private var rcNodeConnAlert = false
    @State private var rcNodeAuthAlert = false
    @State private var rcNodeIsConnecting = false;
    
    var body: some View {
        HStack(alignment: .top){
            VStack(alignment: .leading, spacing: 20) {
                Text("CR Fly Beta").font(.title).bold()
                Text("Connected to aircraft: " + (CRFly.shared.appData.djiDevConn ? "Yes": "No")).font(.title)
                Text("Connected to RC: " + (CRFly.shared.appData.rcNodeConn ? "Yes": "No")).font(.title)
                Text("Bridge Mode Status: " + (CRFly.shared.appData.djiBridgeMode ? "On" : "Off")).font(.title)
                if(CRFly.shared.appData.djiSdkReg){
                    HStack(){
                        if(CRFly.shared.appData.djiDevConn){
                            Button("Lets FLY!"){
                                //Command start FPVmode
                            }.buttonStyle(.bordered).font(.title2)
                            
                            Button("Photo Library"){
                                //Command start libmode
                            }.buttonStyle(.bordered).font(.title2)
                        }
                        
                        if(CRFly.shared.appData.rcNodeConn){
                            Button("RC Node"){
                                //Command start rcnodemode
                            }.buttonStyle(.bordered).font(.title2)
                        }
                    }
                }
                Spacer()
            }
            VStack(alignment: .trailing, spacing: 20){
                if(CRFly.shared.appData.djiSdkReg){
                    if(!CRFly.shared.appData.djiDevConn){
                        Button("Connect"){
                            //Command start connection DJI
                        }.buttonStyle(.bordered).font(.title3).disabled(CRFly.shared.appData.djiDevConn)
                    } else {
                        Button("Disconnect"){
                            //Command stop connection DJI
                        }.buttonStyle(.bordered).font(.title3).disabled(CRFly.shared.appData.djiDevConn)
                    }
                        
                    if(!CRFly.shared.appData.rcNodeConn){
                        Button("Connect"){
                            //Command connect rc
                        }.buttonStyle(.bordered).font(.title3)
                    } else {
                        Button("Disconnect"){
                            //Command connect rc
                        }.buttonStyle(.bordered).font(.title3)
                    }
                        
                    if(CRFly.shared.appData.djiBridgeMode){
                        Button("Stop"){
                            //Command stop bridge mode
                        }.buttonStyle(.bordered).font(.title3)
                    } else {
                        Button("Start"){
                            //Cmd start bridge mode
                        }.buttonStyle(.bordered).font(.title3)
                    }
                }
                Spacer()
            }.padding([.top],50).padding([.horizontal],20)
            
            VStack{
                Button("Scan"){
                    CRFly.shared.viewController.changeView(type: ViewType.scannerView)
                }
            }
            Spacer()
                /*if(self.rcNodeIsConnecting){
                    Color.gray.opacity(0.7).edgesIgnoringSafeArea(.all)
                    ProgressView().scaleEffect(x: 2, y: 2, anchor: .center)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }*/
        }.padding([.top, .horizontal], 60).background(Color.white).foregroundColor(Color.black)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
