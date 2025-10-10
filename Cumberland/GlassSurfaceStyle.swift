import SwiftUI

public struct GlassSurfaceStyle: ViewModifier {
    var cornerRadius: CGFloat
    var shadowRadius: CGFloat
    var shadowOpacity: Double
    var shadowYOffset: CGFloat

    #if os(macOS)
    @State private var isHovering = false
    #endif

    public init(cornerRadius: CGFloat = 12,
                shadowRadius: CGFloat = 12,
                shadowOpacity: Double = 0.12,
                shadowYOffset: CGFloat = 4) {
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.shadowOpacity = shadowOpacity
        self.shadowYOffset = shadowYOffset
    }

    public func body(content: Content) -> some View {
        #if os(visionOS)
        content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .glassBackgroundEffect()
        #else
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.thinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.quaternary, lineWidth: 1)
            )
            .shadow(color: .black.opacity(shadowOpacity),
                    radius: shadowRadius,
                    x: 0,
                    y: shadowYOffset)
            #if os(macOS)
            .onHover { hover in
                withAnimation(.easeInOut(duration: 0.18)) {
                    isHovering = hover
                }
            }
            .scaleEffect(isHovering ? 1.02 : 1.0)
            #endif
        #endif
    }
}

public extension View {
    func glassSurfaceStyle(cornerRadius: CGFloat = 12) -> some View {
        modifier(GlassSurfaceStyle(cornerRadius: cornerRadius))
    }
}
