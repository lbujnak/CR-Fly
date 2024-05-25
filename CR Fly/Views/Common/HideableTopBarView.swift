import SwiftUI

/// `HideableTopBarView` is a SwiftUI view struct that features a dynamic top bar and customizable content area. The top bar can hide based on the scrolling behavior of the content, making it ideal for interfaces where screen real estate needs to be maximized, such as in reading apps or content-heavy interfaces.
public struct HideableTopBarView<TopBar: View, Content: View>: View {
    /// A state variable holding an optional `CGFloat` that stores the initial vertical scroll position when the view first appears. It's used as a reference point to calculate changes in scroll position.
    @State private var initialValue: CGFloat? = nil
    
    /// A state variable holding a `CGFloat` that represents the current offset of the top bar. Positive values indicate the top bar is moving upwards (hiding), and negative values indicate it is moving downwards (revealing).
    @State private var scrollOffset: CGFloat = 0
    
    /// A state variable holding a `CGFloat` that records the last known scroll position, used to determine the direction and magnitude of a scroll event.
    @State private var oldValue: CGFloat = 0
    
    /// A state variable holding an optional  `Timer` that is used to detect when scrolling has stopped to show TopBar. The timer is reset every time a scroll event is detected.
    @State private var timer: Timer? = nil
    
    /// An instance of the `TopBar` view, displayed at the top of this view structure.
    private var topBar: TopBar
    
    /// An instance of the `Content` view, making up the main body of the view structure.
    private var content: Content
    
    /// A boolean that determines whether the content area is wrapped in a `ScrollView`.
    private var scrollable: Bool
    
    /// A `CGFloat` value that defines the initial offset for the scroll content, used to calculate dynamic hiding of the top bar.
    private var scrollStartAt: CGFloat
    
    /** Initializes a `HideableTopBarView`.
    - Parameter topBar: An instance of the `TopBar` view, displayed at the top of this view structure.
    - Parameter content: An instance of the `Content` view, making up the main body of the view structure.
    - Parameter scrollable: A Boolean that determines whether the content area is wrapped in a `ScrollView`. If `true`, the content will be scrollable, allowing the top bar to hide and show based on the scroll behavior. If `false`, the content will be static.
    - Parameter scrollStartAt: A `CGFloat` value that defines the initial offset for the scroll content, used to calculate dynamic hiding of the top bar.
    */
    public init(@ViewBuilder topBar: () -> TopBar, @ViewBuilder content: () -> Content, scrollable: Bool, scrollStartAt: CGFloat) {
        self.topBar = topBar()
        self.content = content()
        self.scrollable = scrollable
        self.scrollStartAt = scrollStartAt
        UIScrollView.appearance().bounces = false
    }
    
    /// Constructs the user interface of the `HideableTopBarView`, organizing the layout into the top bar and content sections.
    public var body: some View {
        VStack {
            // MARK: TopBar
            AnyView(self.topBar).zIndex(2).offset(y: self.scrollOffset)
            
            // MARK: Content
            if !self.scrollable {
                AnyView(self.content)
            } else {
                ScrollView {
                    VStack {
                        GeometryReader { geometry in
                            Color.clear.preference(key: ViewOffsetKey.self, value: geometry.frame(in: .global).minY)
                        }.frame(width: 0, height: 0)
                        
                        AnyView(self.content)
                        
                    }.padding([.top], self.scrollStartAt)
                }.padding([.top], -self.scrollStartAt).zIndex(1)
                    .onPreferenceChange(ViewOffsetKey.self) { value in
                        if self.initialValue == nil {
                            self.oldValue = value
                            self.initialValue = value
                        }
                        
                        let change = value - self.oldValue
                        if change < 0 {
                            if self.initialValue! - value > self.scrollStartAt {
                                if self.scrollOffset + change > -self.initialValue! {
                                    self.scrollOffset += change
                                } else {
                                    self.scrollOffset = -self.initialValue!
                                }
                            }
                        } else if change > 0 {
                            if self.scrollOffset + change < 0 {
                                self.scrollOffset += change
                            } else {
                                self.scrollOffset = 0
                            }
                        }
                        
                        self.oldValue = value
                        self.timer?.invalidate()
                        self.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                            self.scrollOffset = 0
                        }
                    }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            self.scrollOffset = 0
        }
    }
}

/// `ViewOffsetKey` is a `PreferenceKey` in SwiftUI used to accumulate and transmit the vertical scroll offset values across the view hierarchy. It's specifically designed to manage and communicate changes in the scroll position from child views (such as `GeometryReader` frames) to parent views that require this information to adjust their layout or behavior based on scroll activity.
public struct ViewOffsetKey: PreferenceKey {
    /// The initial value for the accumulated offset, set to zero. It represents the starting point for the accumulation of scroll offsets.
    public static var defaultValue: CGFloat = 0
    
    /// Defines how to combine multiple values into a single value. In this case, it accumulates the vertical offsets from multiple views.
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}
