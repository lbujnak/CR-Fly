import DJIUXSDK

/// A `DefaultFPVLayoutController` extends `DUXDefaultLayoutViewController` from the DJI UX SDK. This controller is customized to handle specific view settings for the First Person View (FPV) interface provided by DJI's SDK. This view also contains `DJIWidget` objects that provides access to drone settings and status preview.
public class DefaultFPVLayoutController: DUXDefaultLayoutViewController {
    /// Overrides the `viewDidLoad` method to apply custom settings immediately after the view controller's view loads. The customization includes hiding the camera display name in the FPV and also ensuring that the leading view is hidden to simplify the interface.
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        if super.contentViewController is DUXFPVViewController {
            (super.contentViewController as! DUXFPVViewController).fpvView?.showCameraDisplayName = false
        }
        
        rootView?.leadingView?.isHidden = true
    }
}
