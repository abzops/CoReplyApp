// Extensions.swift
// CoReply
//
// SwiftUI and Foundation extensions for visual style styling and helper logic.

import SwiftUI

// MARK: - Color Hex Initialization (Moved to SharedExtensions.swift)


// MARK: - Glassmorphism Modifier

public struct GlassMorphismModifier: ViewModifier {
    var cornerRadius: CGFloat
    var opacity: Double
    var borderColor: Color
    
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
