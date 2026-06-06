// LoadingView.swift
// CoReplyKeyboard
//
// Animated dots loader view displayed while requesting replies from OpenAI.

import SwiftUI

struct LoadingView: View {
    @State private var dotScale1: CGFloat = 0.5
    @State private var dotScale2: CGFloat = 0.5
    @State private var dotScale3: CGFloat = 0.5
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Circle()
                    .fill(DesignConstants.Colors.primaryAccent)
                    .frame(width: 10, height: 10)
                    .scaleEffect(dotScale1)
                
                Circle()
                    .fill(DesignConstants.Colors.primaryAccent)
                    .frame(width: 10, height: 10)
                    .scaleEffect(dotScale2)
                
                Circle()
                    .fill(DesignConstants.Colors.secondaryAccent)
                    .frame(width: 10, height: 10)
                    .scaleEffect(dotScale3)
            }
            
            Text("Generating replies...")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DesignConstants.Colors.textSecondary)
                .shimmer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            animateDots()
        }
    }
    
    private func animateDots() {
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            dotScale1 = 1.0
        }
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.2)) {
            dotScale2 = 1.0
        }
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.4)) {
            dotScale3 = 1.0
        }
    }
}
