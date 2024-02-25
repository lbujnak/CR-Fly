import Foundation
import DJISDK

struct MediaDownloadState: Equatable {
    let totalMedia: Int
    let totalBytes: Int64
    var downloadedMedia: Int
    var downloadedBytes: Int64
    var downloadSpeed: Float
    var downloadList: [DJIMediaFile]
}
