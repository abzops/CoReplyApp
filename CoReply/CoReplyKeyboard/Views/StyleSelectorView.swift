// StyleSelectorView.swift
// CoReplyKeyboard
//
// Horizontal scrollable tabs selector for reply styles inside keyboard workspace.

import SwiftUI

struct StyleSelectorView: View {
    @Binding var selectedStyle: ReplyStyle
    let onStyleSelected: (ReplyStyle) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ReplyStyle.allCases) { style in
                    let isSelected = selectedStyle == style
                    
                    Button {
                        onStyleSelected(style)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack(spacing: 4) {
                            Text(style.emoji)
                            Text(style.displayName)
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            isSelected ?
                            LinearGradient(
                                colors: [DesignConstants.Colors.primaryAccent, DesignConstants.Colors.secondaryAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) : LinearGradient(colors: [Color.white.opacity(0.06)], startPoint: .center, endPoint: .center)
                        )
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(isSelected ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }
}
