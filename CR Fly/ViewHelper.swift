import SwiftUI

class ViewHelper : ObservableObject {
    @Published var libMode = false
    @Published var libModePicked = false
    @Published var fpvMode = false
    @Published var rcContMode = false
    
    @ObservedObject static var shared = ViewHelper()
}
