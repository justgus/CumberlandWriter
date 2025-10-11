import SwiftUI

public struct GlassToolbarStyle: ViewModifier {
    var cornerRadius: CGFloat
    var padding: CGFloat
    var isInteractive: Bool

    public init(cornerRadius: CGFloat = 14, padding: CGFloat = 6, isInteractive: Bool = true) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.isInteractive = isInteractive
    }

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            #if os(visionOS)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.regularMaterial.opacity(0.8))
            )
            #else
            .glassEffect(
                .regular.interactive(isInteractive),
                in: .rect(cornerRadius: cornerRadius)
            )
            #endif
    }
}

public extension View {
    func glassToolbarStyle(cornerRadius: CGFloat = 14, 
                          padding: CGFloat = 6,
                          isInteractive: Bool = true) -> some View {
        modifier(GlassToolbarStyle(cornerRadius: cornerRadius, 
                                  padding: padding, 
                                  isInteractive: isInteractive))
    }
}
