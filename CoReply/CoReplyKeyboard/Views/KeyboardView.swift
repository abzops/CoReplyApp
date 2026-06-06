// KeyboardView.swift
// CoReplyKeyboard
//
// Main workspace layout containing style tabs, clipboard preview, and reply list.

import SwiftUI

struct KeyboardView: View {
    @ObservedObject var viewModel: KeyboardViewModel
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "0A0A15")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. Header Toolbar
                headerBar
                
                // 2. Clipboard Pill Preview
                clipboardPillView
                
                // 3. Style Bar ScrollView
                StyleSelectorView(selectedStyle: $viewModel.selectedStyle) { style in
                    viewModel.selectStyle(style)
                }
                
                // 4. Central Content Pane
                contentPane
                    .frame(maxHeight: .infinity)
                
                // 5. Footer controls
                footerBar
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Header Toolbar
    
    private var headerBar: some View {
        HStack {
            // App name + logo
            HStack(spacing: 4) {
                Image(systemName: "keyboard")
                    .foregroundColor(DesignConstants.Colors.primaryAccent)
                    .font(.system(size: 13, weight: .bold))
                
                Text("CoReply")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Active Profile + Persona Vibe Indicator
            HStack(spacing: 6) {
                if let profile = viewModel.activeProfile {
                    Text("\(profile.relationshipType.emoji) \(profile.name)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                if let personality = viewModel.activePersonality {
                    Text("•")
                        .foregroundColor(.white.opacity(0.3))
                    Text("\(personality.emoji) \(personality.name)")
                        .font(.system(size: 11))
                        .foregroundColor(DesignConstants.Colors.textSecondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.06))
            .cornerRadius(10)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(height: 38)
    }
    
    // MARK: - Clipboard Preview Pill
    
    private var clipboardPillView: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 12))
                .foregroundColor(DesignConstants.Colors.textSecondary)
            
            if viewModel.clipboardText.isEmpty {
                Text("Clipboard is empty. Copy a message to reply.")
                    .font(.system(size: 12))
                    .foregroundColor(DesignConstants.Colors.textMuted)
                    .lineLimit(1)
            } else {
                Text("\"\(viewModel.clipboardText)\"")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .italic()
            }
            
            Spacer()
            
            // Refresh / Reload clipboard button
            if viewModel.hasFullAccess {
                Button {
                    ClipboardService.shared.syncCurrentClipboard()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 22, height: 22)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.04))
        .frame(height: 34)
    }
    
    // MARK: - Content Router
    
    @ViewBuilder
    private var contentPane: some View {
        if viewModel.isLoading {
            LoadingView()
        } else if let err = viewModel.error {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(DesignConstants.Colors.warning)
                
                Text(err)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignConstants.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                if viewModel.hasFullAccess && !viewModel.clipboardText.isEmpty && !viewModel.dailyLimitReached {
                    Button {
                        Task { await viewModel.generateReplies() }
                    } label: {
                        Text("Retry")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(DesignConstants.Colors.primaryAccent)
                            .cornerRadius(8)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.dailyLimitReached {
            VStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 28))
                    .foregroundColor(DesignConstants.Colors.premiumGold)
                
                Text("Daily Reply Limit Reached")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Upgrade to Pro in CoReply app for unlimited reply suggestions.")
                    .font(.system(size: 11))
                    .foregroundColor(DesignConstants.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.replies.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "arrow.right.doc.on.clipboard")
                    .font(.system(size: 28))
                    .foregroundColor(DesignConstants.Colors.textMuted)
                
                Text("Waiting for copied text")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("Copy a message from your chat thread, then open the keyboard here.")
                    .font(.system(size: 11))
                    .foregroundColor(DesignConstants.Colors.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // Reply Suggestion Scroll Cards
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 10) {
                    ForEach(viewModel.replies) { reply in
                        ReplyCardView(reply: reply) {
                            viewModel.insertReply(reply)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Footer controls
    
    private var footerBar: some View {
        HStack {
            // Switch Keyboard Globe
            Button {
                viewModel.advanceToNextKeyboard()
            } label: {
                Image(systemName: "globe")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Limit Meter
            if viewModel.repliesRemaining < 1000 {
                Text("\(viewModel.repliesRemaining) replies left")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(viewModel.repliesRemaining < 5 ? DesignConstants.Colors.danger : DesignConstants.Colors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(8)
            }
            
            Spacer()
            
            // Regenerate suggestions
            Button {
                Task {
                    await viewModel.generateReplies()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(
                        LinearGradient(
                            colors: [DesignConstants.Colors.primaryAccent, DesignConstants.Colors.secondaryAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: DesignConstants.Colors.primaryAccent.opacity(0.3), radius: 6, y: 2)
            }
            .disabled(viewModel.isLoading || viewModel.clipboardText.isEmpty || viewModel.dailyLimitReached)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(height: 48)
        .background(Color(hex: "08080E"))
    }
}
