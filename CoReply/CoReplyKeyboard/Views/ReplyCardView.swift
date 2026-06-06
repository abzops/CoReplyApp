// ReplyCardView.swift
// CoReplyKeyboard
//
// Card layout rendering generated text reply options with scoring labels.

import SwiftUI

struct ReplyCardView: View {
    let reply: Reply
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var isExpanded = false
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    // Style label badge
                    HStack(spacing: 3) {
                        Text(reply.style.emoji)
                        Text(reply.style.displayName)
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(DesignConstants.Colors.primaryAccent.opacity(0.25))
                    .cornerRadius(6)
                    
                    Spacer()
                    
                    // Score indicator
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                        Text(String(format: "%.1f", reply.score.overall * 10))
                            .font(.system(size: 10, weight: .black))
                    }
                    .foregroundColor(DesignConstants.Colors.premiumGold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(6)
                }
                
                // Reply Text content
                Text(reply.text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(isExpanded ? nil : 3)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Show expand button if text is long
                if reply.text.count > 120 {
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                isExpanded.toggle()
                            }
                        } label: {
                            Text(isExpanded ? "Show Less" : "Expand")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(DesignConstants.Colors.primaryAccent)
                        }
                    }
                }
            }
            .padding(12)
            .glassMorphism(cornerRadius: 12)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.8), value: isPressed)
        }
        .buttonStyle(CardButtonStyle(isPressed: $isPressed))
    }
}

// Custom button style to intercept press interactions for scale animation
struct CardButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { newValue in
                isPressed = newValue
            }
    }
}
