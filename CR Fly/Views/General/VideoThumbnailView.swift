import SwiftUI
import AVKit

struct VideoThumbnailView: View {
    let videoURL: URL
    @State private var thumbnailImage: UIImage?

    var body: some View {
        Image(uiImage: thumbnailImage ?? UIImage(systemName: "photo")!)
            .resizable().scaledToFill().frame(width: 140, height: 100).clipped()
            .onAppear {
                thumbnailImage = self.generateThumbnail(for: videoURL)
            }
    }
    
    private func generateThumbnail(for url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImageGenerator.appliesPreferredTrackTransform = true  

        let timestamp = CMTime(seconds: 1, preferredTimescale: 60)

        do {
            let imageRef = try assetImageGenerator.copyCGImage(at: timestamp, actualTime: nil)
            return UIImage(cgImage: imageRef)
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}
