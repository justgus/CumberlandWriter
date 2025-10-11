// InnerShadowModifier.swift
import SwiftUI

extension View {
    func innerShadow(cornerRadius: CGFloat, color: Color, radius: CGFloat, offset: CGSize) -> some View {
        self.modifier(InnerShadowModifier(cornerRadius: cornerRadius, color: color, radius: radius, offset: offset))
    }
}

private struct InnerShadowModifier: ViewModifier {
    let cornerRadius: CGFloat
    let color: Color
    let radius: CGFloat
    let offset: CGSize
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(color, lineWidth: radius * 0.3)
                    .blur(radius: radius * 0.5)
                    .offset(offset)
                    .mask(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .black, location: 0),
                                    .init(color: .clear, location: 1)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                    )
                    .allowsHitTesting(false)
            )
    }
}