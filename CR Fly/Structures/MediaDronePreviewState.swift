import Foundation
import DJISDK

struct MediaDronePreviewState {
    let media: DJIMediaFile
    var currentTime: Float
    var isPlaying: Bool
    var isPreparing: Bool
    var isUserChangingTime: Bool
    let totalTime: Float
}
