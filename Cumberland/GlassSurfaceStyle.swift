//
//  GlassSurfaceStyle.swift
//  Cumberland
//
//  ViewModifier that applies a glass-morphism surface treatment with optional
//  tint color, adjustable corner radius, and hover-scaling on macOS. Exposes
//  a .glassSurface(…) View convenience extension. Intended for card panels
//  and inspector backgrounds.
//

import SwiftUI

public struct GlassSurfaceStyle: ViewModifier {
    var cornerRadius: CGFloat
    var isInteractive: Bool
    var tintColor: Color?

    #if os(macOS)
    @State private var isHovering = false
    #endif

    public init(cornerRadius: CGFloat = 12,
                isInteractive: Bool = false,
                tintColor: Color? = nil) {
        self.cornerRadius = cornerRadius
        self.isInteractive = isInteractive
        self.tintColor = tintColor
    }

    public func body(content: Content) -> some View {
        content
            #if os(visionOS)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial, style: FillStyle())
                    .overlay {
                        if let tintColor {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(tintColor.opacity(0.3))
                        }
                    }
            }
            #else
            .glassEffect(
                .regular
                    .tint(tintColor ?? .clear)
                    .interactive(isInteractive),
                in: .rect(cornerRadius: cornerRadius)
            )
            #endif
            #if os(macOS)
            .onHover { hover in
                withAnimation(.easeInOut(duration: 0.18)) {
                    isHovering = hover
                }
            }
            .scaleEffect(isHovering && isInteractive ? 1.02 : 1.0)
            #endif
    }
}

public extension View {
    func glassSurfaceStyle(cornerRadius: CGFloat = 12, 
                          isInteractive: Bool = false,
                          tintColor: Color? = nil) -> some View {
        modifier(GlassSurfaceStyle(cornerRadius: cornerRadius, 
                                  isInteractive: isInteractive,
                                  tintColor: tintColor))
    }
}
