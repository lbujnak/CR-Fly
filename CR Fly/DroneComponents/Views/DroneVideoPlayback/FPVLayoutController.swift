import DJIUXSDK

/// A `DefaultFPVLayoutController` extends `DUXFPVViewController` from the DJI UX SDK. This controller is customized to handle specific view settings for theview settings for the First Person View (FPV) interface provided by DJI's SDK. This view does not contain widgets and only display/provide access to live-video feed for video preview in album.
public class FPVLayoutController: DUXFPVViewController {
    ///  This class overrides the `viewDidLoad` method to apply custom settings immediately after the view controller's view loads. The customization includes hiding the camera display name in the FPV and disable interaction with view.
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        fpvView?.showCameraDisplayName = false
        isHUDInteractionEnabled = false
    }
}
