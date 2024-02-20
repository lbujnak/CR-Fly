import SwiftUI
import DJIUXSDK
import DJISDK

struct AlbumDroneVideoPlayback: UIViewControllerRepresentable{
    
    func makeUIViewController(context: Context) -> UIViewController{
        let storyboard = UIStoryboard(name: "VideoPlaybackView", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(identifier: "VideoPlaybackView")
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}
