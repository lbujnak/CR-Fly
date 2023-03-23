import SwiftUI

struct RCNodeView: View {
    
    @ObservedObject var viewHelper = ViewHelper.shared
    
    var body: some View {
        VStack{
            HStack(spacing: 30){
                Button("←"){
                    self.viewHelper.rcContMode = false
                }.foregroundColor(.gray).font(.largeTitle)
                Spacer()
            }
            Spacer()
        }.background(Color.black.ignoresSafeArea()).alert(isPresented: GlobalAlertHelper.$shared.active){ Alert(title: GlobalAlertHelper.shared.title, message: GlobalAlertHelper.shared.msg, dismissButton: .cancel()) }
    }
}

struct RCNodeView_Previews: PreviewProvider {
    static var previews: some View {
        RCNodeView()
    }
}
