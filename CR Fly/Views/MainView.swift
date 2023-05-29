import SwiftUI

struct MainView: View {
    
    @State private var bridgeConnAlert = false
    @State private var rcNodeConnAlert = false
    @State private var rcNodeAuthAlert = false
    @State private var rcNodeIsConnecting = false;
    
    @State var rcIPAddr = "192.168.10.15" //"192.168.11.100"
    @State var rcAuthToken = "674746F1-C361-413B-B427-BD769E7BE96E" //"383F0345-9E6E-461F-907F-534337987967"
    
    @ObservedObject var viewHelper = ViewHelper.shared
    @ObservedObject var djiService = ProductCommunicationService.shared
    @ObservedObject var rcNodeService = RCNodeCommunicationService.shared
    @ObservedObject var alertHelper = GlobalAlertHelper.shared
    
    var body: some View {
        ZStack{
            HStack(alignment: .top){
                VStack(alignment: .leading, spacing: 20) {
                    Text("CR Fly Beta").font(.title).bold()
                    Text("Connected to aircraft: " + (self.djiService.connected ? "Yes": "No")).font(.title)
                    Text("Connected to RC: " + (self.rcNodeService.autorized ? "Yes": "No")).font(.title)
                    Text("Bridge Mode Status: " + (self.djiService.enableBridgeMode ? "On" : "Off")).font(.title)
                    if(self.djiService.sdkRegistered){
                        HStack(){
                            if(self.djiService.connected){
                                Button("Lets FLY!"){
                                    self.djiService.libController.prepareFPV(){ (error) in
                                        if(error != nil){
                                            GlobalAlertHelper.shared.createAlert(title: "Error", msg: "There was a problem opening fpv view: \(String(describing: error)).")
                                        }
                                        else { self.viewHelper.fpvMode = true }
                                    }
                                }.buttonStyle(.bordered).font(.title2)
                                
                                Button("Photo Library"){
                                    self.djiService.libController.startPlaybackMode(completionHandler: {(error) in
                                        if(error != nil) {
                                            GlobalAlertHelper.shared.createAlert(title: "Error", msg: "There was a problem opening library: \(String(describing: error)).")
                                        } else{ self.viewHelper.libMode = true }
                                    })
                                }.buttonStyle(.bordered).font(.title2)
                            }
                            if(self.rcNodeService.autorized){
                                Button("RC Node"){
                                    ViewHelper.shared.rcContMode = true
                                }.buttonStyle(.bordered).font(.title2)
                            }
                        }
                    }
                    Spacer()
                }
                VStack(alignment: .trailing, spacing: 20){
                    if(self.djiService.sdkRegistered){
                        if(!self.djiService.connected){
                            Button("Connect"){
                                self.djiService.connectToProduct()
                            }.buttonStyle(.bordered).font(.title3).disabled(self.djiService.connected)
                        } else {
                            Button("Disconnect"){
                                self.djiService.disconnect()
                            }.buttonStyle(.bordered).font(.title3).disabled(self.djiService.connected)
                        }
                        
                        if(!self.rcNodeService.autorized){
                            Button("Connect"){
                                self.rcNodeConnAlert = true;
                            }.alert("Connect", isPresented: self.$rcNodeConnAlert, actions: {
                                TextField("IP Address", text: self.$rcIPAddr)
                                TextField("Auth Token", text: self.$rcAuthToken)
                                Button("Connect") {
                                    self.rcNodeIsConnecting = true
                                    self.rcNodeService.connectUserToRc(ip: self.rcIPAddr, authToken: self.rcAuthToken){ (valid) in
                                        DispatchQueue.main.async {
                                            self.rcNodeIsConnecting = false
                                        }
                                    }
                                }
                            },message: {
                                Text("Please enter (local) ip address of computer runing RCNode and access token, located in RealityCapture Second-Screen to authorize this device.")
                            }).buttonStyle(.bordered).font(.title3)
                        } else {
                            Button("Disconnect"){
                                self.rcNodeService.closeConnection()
                            }.buttonStyle(.bordered).font(.title3)
                        }
                        
                        
                        if(self.djiService.enableBridgeMode){
                            Button("Stop"){
                                self.djiService.stopBridgeMode()
                            }.buttonStyle(.bordered).font(.title3)
                        } else {
                            Button("Start"){
                                self.bridgeConnAlert = true
                            }.alert("Start", isPresented: self.$bridgeConnAlert, actions: {
                                TextField("IP Address", text: self.$djiService.bridgeAppIP)
                                Button("Start", action: {
                                    self.djiService.enableBridgeMode = true
                                    self.djiService.connectToProduct()
                                })
                                Button("Cancel", role: .cancel, action: {})
                            }, message: {
                                Text("Please enter IP Address of device running SDK Bridge App.")
                            }).buttonStyle(.bordered).font(.title3)
                        }
                    }
                }.padding([.top],50).padding([.horizontal],20)
                Spacer()
            }.padding([.top, .horizontal], 60).alert(isPresented: self.$alertHelper.active){ Alert(title: self.alertHelper.title, message: self.alertHelper.msg, dismissButton: .cancel()) }
            
            if(self.rcNodeIsConnecting){
                Color.gray.opacity(0.7).edgesIgnoringSafeArea(.all)
                ProgressView().scaleEffect(x: 2, y: 2, anchor: .center)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
    }
}
