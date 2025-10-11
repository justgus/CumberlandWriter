// LiquidGlassModifiers.swift
import SwiftUI

// MARK: - Liquid Glass View Modifiers

extension View {
    /// Apply modern liquid glass effect using SwiftUI's native glass APIs
    func modernGlassEffect(_ glass: Glass = .regular, in shape: GlassShape = .capsule) -> some View {
        self.modifier(ModernLiquidGlassModifier(glass: glass, shape: shape))
    }
    
    /// Apply glass surface styling for content areas with proper Liquid Glass design
    func glassSurfaceStyle(cornerRadius: CGFloat = 16, tint: Color? = nil, interactive: Bool = false) -> some View {
        self.modifier(GlassSurfaceModifier(cornerRadius: cornerRadius, tint: tint, interactive: interactive))
    }
    
    /// Apply glass toolbar styling with proper Liquid Glass design
    func glassToolbarStyle(tint: Color? = nil, interactive: Bool = true) -> some View {
        self.modifier(GlassToolbarModifier(tint: tint, interactive: interactive))
    }
    
    /// Apply glass button styling
    func glassButtonStyle(prominent: Bool = false, tint: Color? = nil) -> some View {
        if prominent {
            self.buttonStyle(.glassProminent)
        } else {
            self.buttonStyle(.glass)
        }
    }
    
    /// Create a glass effect container for multiple glass elements
    func glassContainer(spacing: CGFloat = 20.0, @ViewBuilder content: () -> some View) -> some View {
        GlassEffectContainer(spacing: spacing) {
            content()
        }
    }
}

// MARK: - Glass Shapes

enum GlassShape {
    case rect(cornerRadius: CGFloat)
    case circle
    case capsule
    
    var swiftUIShape: any Shape {
        switch self {
        case .rect(let cornerRadius):
            return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        case .circle:
            return Circle()
        case .capsule:
            return Capsule()
        }
    }
}

// MARK: - View Modifiers

private struct ModernLiquidGlassModifier: ViewModifier {
    let glass: Glass
    let shape: GlassShape
    
    func body(content: Content) -> some View {
        content
            .glassEffect(glass, in: shapeForGlassEffect)
    }
    
    @ViewBuilder
    private var shapeForGlassEffect: some View {
        switch shape {
        case .rect(let cornerRadius):
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        case .circle:
            Circle()
        case .capsule:
            Capsule()
        }
    }
}

private struct GlassSurfaceModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color?
    let interactive: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .glassEffect(glassConfiguration, in: .rect(cornerRadius: cornerRadius))
    }
    
    private var glassConfiguration: Glass {
        var glass = Glass.regular
        
        if let tint {
            glass = glass.tint(tint)
        }
        
        if interactive {
            glass = glass.interactive()
        }
        
        return glass
    }
}

private struct GlassToolbarModifier: ViewModifier {
    let tint: Color?
    let interactive: Bool
    
    func body(content: Content) -> some View {
        content
            .glassEffect(glassConfiguration, in: .capsule)
    }
    
    private var glassConfiguration: Glass {
        var glass = Glass.regular
        
        if let tint {
            glass = glass.tint(tint)
        }
        
        if interactive {
            glass = glass.interactive()
        }
        
        return glass
    }
}

// MARK: - Glass Effect Containers and Specialized Views

/// A view that creates a glass card with proper Liquid Glass design
struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let tint: Color?
    let interactive: Bool
    @ViewBuilder let content: () -> Content
    
    init(cornerRadius: CGFloat = 16, 
         tint: Color? = nil, 
         interactive: Bool = false,
         @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.interactive = interactive
        self.content = content
    }
    
    var body: some View {
        content()
            .padding()
            .glassSurfaceStyle(cornerRadius: cornerRadius, tint: tint, interactive: interactive)
    }
}

/// A view that creates a glass panel for settings and configuration
struct GlassSettingsPanel<Content: View>: View {
    let title: String
    let icon: String?
    let tint: Color?
    @ViewBuilder let content: () -> Content
    
    init(_ title: String, 
         icon: String? = nil,
         tint: Color? = nil,
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.icon = icon
        self.tint = tint
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let icon {
                    Image(systemName: icon)
                        .foregroundStyle(.secondary)
                }
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            content()
        }
        .glassSurfaceStyle(cornerRadius: 16, tint: tint, interactive: false)
    }
}

/// A glass toolbar that can adapt its contents and morph between different states
struct AdaptiveGlassToolbar<Content: View>: View {
    let tint: Color?
    let interactive: Bool
    @ViewBuilder let content: () -> Content
    
    init(tint: Color? = nil, 
         interactive: Bool = true,
         @ViewBuilder content: @escaping () -> Content) {
        self.tint = tint
        self.interactive = interactive
        self.content = content
    }
    
    var body: some View {
        HStack {
            content()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassToolbarStyle(tint: tint, interactive: interactive)
    }
}

// MARK: - Glass Form Sections

/// A glass-styled form section that follows Liquid Glass design principles
struct GlassFormSection<Content: View>: View {
    let title: String?
    let footer: String?
    let tint: Color?
    @ViewBuilder let content: () -> Content
    
    init(_ title: String? = nil,
         footer: String? = nil,
         tint: Color? = nil,
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.footer = footer
        self.tint = tint
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            
            VStack(spacing: 0) {
                content()
            }
            .glassSurfaceStyle(cornerRadius: 12, tint: tint, interactive: false)
            
            if let footer {
                Text(footer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
        }
    }
}