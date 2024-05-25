import SwiftUI

/// `ImageThumbnailView` is a SwiftUI view designed to asynchronously load, resize, and display an image from a specified URL. This view handles image downloading and processing, making it suitable for displaying image previews in a user interface, such as in a media gallery or during file selection processes.
public struct ImageThumbnailView: View {
    /// A `DocURL` of the image file to be displayed as a thumbnail.
    private let url: DocURL
    
    /// An oprional state variable holding the resized thumbnail image; it is initially nil and set upon image download and processing.
    @State private var uiImage: UIImage? = nil
    
    /** Initializes an `ImageThumbnailView`.
    - Parameter url: The URL of the image file to be displayed as a thumbnail.
    */
    public init(url: DocURL) {
        self.url = url
    }
    
    /// Builds the user interface for the `ImageThumbnailView`, including an image view that may display a resized image or a loading indicator.
    public var body: some View {
        Group {
            if let uiImage = uiImage {
                Image(uiImage: uiImage).resizable().scaledToFill()
            } else {
                ProgressView().onAppear(perform: loadImage)
            }
        }
    }
    
    /// Loads the image from the specified URL, resizes it, and updates the `uiImage` state variable.
    private func loadImage() {
        let task = URLSession.shared.dataTask(with: url.getURL()) { data, response, error in
            guard let data = data, let image = UIImage(data: data) else {
                return
            }
            
            let resizedImage = ImageThumbnailView.resizeImage(image: image, targetSize: CGSize(width: 70, height: 50))
            
            DispatchQueue.main.async {
                self.uiImage = resizedImage
            }
        }
        task.resume()
    }
    
    /// Resizes the given `UIImage` to the specified target size while maintaining the original aspect ratio.
    public static func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let newSize = CGSize(width: size.width * widthRatio, height: size.height * heightRatio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
}
