import SwiftUI
@testable import CR_Fly

struct MockTextView: AppearableView {
    private var text : String
    
    func appear() { return }
    func disappear() { return }
    init(txt: String) { self.text = txt }
    
    var body: some View { Text(self.text) }
}
