import Foundation
import DJISDK
import DJIUXSDK
import DJIWidget

class VideoPlaybackController: UIViewController, DJICameraDelegate{

    @IBOutlet weak var playbackView: UIView!
    var adapter: VideoPreviewerAdapter?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let product = DJISDKManager.product() else{ return }
        guard let camera = product.camera else { return }
        camera.delegate = self
        
        DJIVideoPreviewer.instance()?.start()        
        adapter = VideoPreviewerAdapter.init()
        adapter?.start()
        
        if camera.displayName == DJICameraDisplayNameMavic2ZoomCamera ||
            camera.displayName == DJICameraDisplayNameDJIMini2Camera ||
            camera.displayName == DJICameraDisplayNameMavicAir2Camera ||
            camera.displayName == DJICameraDisplayNameDJIAir2SCamera ||
            camera.displayName == DJICameraDisplayNameMavic2ProCamera {
            adapter?.setupFrameControlHandler()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DJIVideoPreviewer.instance()?.type = DJIVideoPreviewerType.autoAdapt
        DJIVideoPreviewer.instance()?.start()
        DJIVideoPreviewer.instance()?.setView(playbackView)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        DJIVideoPreviewer.instance()?.unSetView()
        
        if adapter != nil {
            adapter?.stop()
            adapter = nil
        }
    }
}
