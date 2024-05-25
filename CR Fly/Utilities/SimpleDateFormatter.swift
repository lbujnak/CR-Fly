import Foundation

/**
 `SimpleDateFormatter` is a subclass of `DateFormatter` tailored specifically to provide standardized date formatting across the application. It ensures consistency in how dates are represented, particularly focusing on a standard format suitable for user interfaces or data handling where date values need to be expressed in a consistent and readable format.
 
 - Usage: This class is particularly useful in scenarios where dates need to be formatted precisely without the risk of variations due to environmental differences on user devices.
 */
public class SimpleDateFormatter: DateFormatter {
    /// Initializes a new instance of `SimpleDateFormatter`. This initializer configures the formatter with a predefined date format and locale that are optimized for consistent application-wide use.
    override init() {
        super.init()
        dateFormat = "yyyy-MM-dd"
        locale = Locale(identifier: "en_US_POSIX")
    }
    
    /**
     Required initializer for decoding a `SimpleDateFormatter` from an archive or serialization. It ensures that the formatter can be used with storyboard and serialization frameworks like NSCoder.
     - Parameter coder: An archiver or deserializer that provides a way to decode the previously encoded formatter.
     */
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    /**
     Static method to format a time interval, given in seconds, into a human-readable string representing hours, minutes, and seconds or just minutes and seconds if under an hour.
     - Parameter seconds: The total time interval in seconds that needs to be formatted.
     - Returns: A string that represents the formatted time. The format is adaptive based on the length of the time interval- if the total seconds amount to an hour or more, it formats time as "HH:mm:ss" else as "mm:ss".
     */
    public static func formatTime(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format: "%02i:%02i", minutes, seconds)
        }
    }
}
