import SwiftUI

struct DroneFPVView: View {
    var body: some View {
        ZStack{
            DefaultFPVLayoutStoryboard().edgesIgnoringSafeArea(.all)
            
            VStack{
                HStack{
                    Button("←"){
                        ViewHelper.shared.fpvMode = false
                    }.foregroundColor(.white).padding([.horizontal],-40).padding([.top],40).font(.largeTitle)
                    Spacer()
                }
                Spacer()
            }
        }.alert(isPresented: GlobalAlertHelper.$shared.active){ Alert(title: GlobalAlertHelper.shared.title, message: GlobalAlertHelper.shared.msg, dismissButton: .cancel()) }
    }
}

struct DroneFPVView_Previews: PreviewProvider {
    static var previews: some View {
        DroneFPVView()
    }
}

struct DefaultFPVLayoutStoryboard: UIViewControllerRepresentable{
    
    func makeUIViewController(context: Context) -> UIViewController{
        let storyboard = UIStoryboard(name: "DJIDefaultFPV", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(identifier: "DJIDefaultFPV")
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}
