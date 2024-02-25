import Foundation

class SimpleDateFormatter: DateFormatter {
    override init() {
        super.init()
        self.dateFormat = "yyyy-MM-dd"
        self.locale = Locale(identifier: "en_US_POSIX")
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    static public func formatTime(_ seconds: Double) -> String {
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
