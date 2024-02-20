import SwiftUI
import DJISDK

class ExitDronePreview: DroneCommand {
    var file: DJIMediaFile
    
    init(file: DJIMediaFile) {
        self.file = file
    }
    
    private var appData = CRFly.shared.appData
    
    func execute(completion: @escaping () -> Void) {
        self.file.resetPreview()
        self.appData.djiMediaPreviewState = nil
        completion()
    }
}
