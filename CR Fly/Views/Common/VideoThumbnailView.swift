import AVKit
import SwiftUI

/// `VideoThumbnailView` is a SwiftUI view designed to generate and display a thumbnail image for a video file specified by a URL. This view integrates directly with `AVKit` to handle video processing, making it efficient for displaying previews in a user interface, such as in a media library or during file selection processes.
public struct VideoThumbnailView: View {
    /// Stores the URL of the video file from which the thumbnail is generated.
    private let videoURL: DocURL
    
    /// An optional state variable holding the thumbnail image; it is initially nil and set upon view appearance.
    @State private var thumbnailImage: UIImage?
    
    /** Initializes a `VideoThumbnailView`.
    - Parameter videoUrl: Stores the URL of the video file from which the thumbnail is generated.
    */
    public init(videoURL: DocURL) {
        self.videoURL = videoURL
    }
    
    /// Builds the user interface for the `VideoThumbnailView`, including an image view that may display a generated thumbnail or a default placeholder.
    public var body: some View {
        ZStack {
            if self.thumbnailImage != nil {
                Image(uiImage:  ImageThumbnailView.resizeImage(image: self.thumbnailImage!, targetSize: CGSize(width: 70, height: 50)))
                    .resizable().scaledToFill().frame(width: 140, height: 100).clipped()
            }
        }
        .onAppear {
            self.thumbnailImage = self.generateThumbnail(for: self.videoURL)
        }
    }
    
    /// Generates a thumbnail image for a video at the specified URL by extracting an image frame from the video.
    private func generateThumbnail(for url: DocURL) -> UIImage? {
        let asset = AVAsset(url: url.getURL())
        let timestamp = CMTime(seconds: 1, preferredTimescale: 60)
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let imageRef = try assetImageGenerator.copyCGImage(at: timestamp, actualTime: nil)
            return UIImage(cgImage: imageRef)
        } catch {
            print("Error Creating Video Thumbnail For Saved Lib: \(error.localizedDescription)")
            return nil
        }
    }
}
