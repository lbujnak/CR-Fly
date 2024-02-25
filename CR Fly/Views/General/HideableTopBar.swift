import SwiftUI

public struct HideableTopBar<TopBar: View, Content: View>: View {
    
    private var topBar: TopBar
    private var content: Content
    private var scrollable: Bool
    private var scrollStartAt: CGFloat
    
    @State private var initialValue: CGFloat? = nil
    @State private var scrollOffset: CGFloat = 0
    @State private var oldValue: CGFloat = 0
    
    public init(@ViewBuilder topBar: () -> TopBar, @ViewBuilder content: () -> Content, scrollable: Bool, scrollStartAt: CGFloat) {
        self.topBar = topBar()
        self.content = content()
        self.scrollable = scrollable
        self.scrollStartAt = scrollStartAt
        UIScrollView.appearance().bounces = false
    }
    
    public var body: some View {
        VStack {
            AnyView(self.topBar).zIndex(2).offset(y: self.scrollOffset)
            
            if(!self.scrollable){
                AnyView(self.content)
            }
            else {
                ScrollView() {
                    VStack {
                        GeometryReader { geometry in
                            Color.clear.preference(key: ViewOffsetKey.self, value: geometry.frame(in: .global).minY)
                        }.frame(width: 0, height: 0)
                        
                        AnyView(self.content)
                    }.padding([.top],self.scrollStartAt)
                }.padding([.top],-self.scrollStartAt).zIndex(1)
                .onPreferenceChange(ViewOffsetKey.self) { value in
                    if(self.initialValue == nil) {
                        self.oldValue = value
                        self.initialValue = value
                    }
                    let change = value - self.oldValue
                    
                    if(change < 0){
                        if(self.initialValue! - value > self.scrollStartAt){
                            if(self.scrollOffset + change > -self.initialValue!){
                                self.scrollOffset += change
                            } else {
                                self.scrollOffset = -self.initialValue!
                            }
                        }
                    } else if (change > 0){
                        if(self.scrollOffset + change < 0){
                            self.scrollOffset += change
                        } else {
                            self.scrollOffset = 0
                        }
                    }
                    self.oldValue = value
                }
            }
            
            
        }.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            self.scrollOffset = 0
        }
    }
}

struct ViewOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}
