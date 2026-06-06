// SharedExtensions.swift
// CoReply
//
// Shared extensions accessible by both the Main App and Keyboard Extension targets.

import SwiftUI

// MARK: - Color Hex Initialization

extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Glassmorphism Modifier

public struct GlassMorphismModifier: ViewModifier {
    var cornerRadius: CGFloat
    var opacity: Double
    var borderColor: Color
    
    public init(cornerRadius: CGFloat, opacity: Double, borderColor: Color) {
        self.cornerRadius = cornerRadius
        self.opacity = opacity
        self.borderColor = borderColor
    }
    
    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(opacity))
            )
            .background(
                VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
                    .cornerRadius(cornerRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// Helper VisualEffectView wrapper for UIKit UIVisualEffectView
public struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    
    public init(effect: UIVisualEffect? = nil) {
        self.effect = effect
    }
    
    public func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: effect)
    }
    
    public func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = effect
    }
}

extension View {
    public func glassMorphism(cornerRadius: CGFloat = 16, opacity: Double = 0.07, borderColor: Color = Color.white.opacity(0.12)) -> some View {
        self.modifier(GlassMorphismModifier(cornerRadius: cornerRadius, opacity: opacity, borderColor: borderColor))
    }
}

// MARK: - Shimmer Effect Modifier

public struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    public init() {}
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.15), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: -geo.size.width + (phase * geo.size.width * 2))
                    .mask(content)
                }
            )
            .onAppear {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    public func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

// MARK: - Safe Array Subscript

extension Array {
    public subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
