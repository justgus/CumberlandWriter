import SwiftUI

public struct GlassToolbarStyle: ViewModifier {
    var cornerRadius: CGFloat
    var padding: CGFloat

    public init(cornerRadius: CGFloat = 14, padding: CGFloat = 6) {
        self.cornerRadius = cornerRadius
        self.padding = padding
    }

    public func body(content: Content) -> some View {
        #if os(visionOS)
        content
            .padding(padding)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .glassBackgroundEffect()
        #else
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.thinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.quaternary, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 3)
        #endif
    }
}

public extension View {
    func glassToolbarStyle(cornerRadius: CGFloat = 14, padding: CGFloat = 6) -> some View {
        modifier(GlassToolbarStyle(cornerRadius: cornerRadius, padding: padding))
    }
}
