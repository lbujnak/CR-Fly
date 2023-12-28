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
}
