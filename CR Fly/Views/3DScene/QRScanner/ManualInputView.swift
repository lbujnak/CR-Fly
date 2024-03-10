import SwiftUI

struct ManualInputView: View {
    
    @Binding var manualInput: Bool
    @Binding var verifyStatus: String
    @Binding var verifyingQRCode: Bool
    
    @State var manualIPAddr: String = "192.168.10.15"
    @State var manualAuthTok: String = "674746F1-C361-413B-B427-BD769E7BE96E"
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(){
                VStack(spacing: 8) {
                    // MARK: Header bar + info
                    HStack{
                        Button("←"){
                            self.manualInput = false
                        }.font(.largeTitle).foregroundColor(.primary)
                        
                        Spacer()
                        Text("Please enter IP Address and Auth Token from RealityCapture").font(.title3).foregroundColor(.primary.opacity(0.8)).padding(.top,20).padding(.top,-20)
                        
                        Spacer()
                    }.ignoresSafeArea()
                    
                    HStack{
                        Text("Alternatively, you can confirm pre-filled fields to reestablish the previous connection.").foregroundColor(.secondary)
                    }.font(.callout).padding(.top,-10)
                    
                    Spacer()
                    
                    // MARK: Inputs and ConnectBtn
                    Group {
                        HStack{
                            Text("IP Address:")
                            Spacer()
                            TextField("IP Address", text: self.$manualIPAddr)
                                .padding([.top,.bottom], 5).padding([.leading, .trailing],15)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10).frame(width: 250).multilineTextAlignment(.leading)
                        }.frame(minWidth: 360 ,maxWidth: 360)
                        HStack{
                            Text("Auth Token:")
                            Spacer()
                            TextField("Auth Token", text: self.$manualAuthTok)
                                .padding([.top,.bottom], 5).padding([.leading, .trailing],15)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10).frame(width: 250).multilineTextAlignment(.leading)
                        }.frame(minWidth: 360 ,maxWidth: 360)
                        HStack{
                            Button {
                                self.verifyStatus = "Connecting to RealityCapture..."
                                self.verifyingQRCode = true
                                self.manualInput = false
                                //CRFly.shared.appData.rcNodeIP = self.manualIPAddr
                                //CRFly.shared.appData.rcAuthTkn = self.manualAuthTok
                                
                                //Command connect to RC
                            } label: {
                                Text("Connect").frame(minWidth: 360 ,maxWidth: 360, minHeight: 40, maxHeight: 40).foregroundColor(.white)
                            }.background(Color.blue).cornerRadius(8)
                        }.padding([.top],15)
                    }
                    Spacer()
                }.padding(15).frame(width: geometry.size.width, height: geometry.size.height).multilineTextAlignment(.center)
            }.scrollDismissesKeyboard(.immediately)
        }
    }
}

#Preview {
    ManualInputView(manualInput: .constant(true), verifyStatus: .constant("Connecting..."), verifyingQRCode: .constant(false))
}
