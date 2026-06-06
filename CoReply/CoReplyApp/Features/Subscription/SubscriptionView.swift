// SubscriptionView.swift
// CoReply
//
// Paywall view showing monetization benefits, tier options, and StoreKit checkout CTAs.

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SubscriptionViewModel()
    @State private var selectedProductID: String = ""
    
    var body: some View {
        ZStack {
            // Background
            DesignConstants.Gradients.primaryBackground
                .ignoresSafeArea()
            
            // Neon Glows
            Circle()
                .fill(DesignConstants.Colors.primaryAccent.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: -50, y: -200)
            
            Circle()
                .fill(DesignConstants.Colors.secondaryAccent.opacity(0.1))
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .offset(x: 80, y: 180)
            
            VStack(spacing: 0) {
                // Top Dismiss Button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignConstants.Spacing.lg) {
                        
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(DesignConstants.Gradients.premiumGradient)
                                .shadow(color: DesignConstants.Colors.premiumGold.opacity(0.5), radius: 12)
                                .padding(.bottom, 4)
                            
                            Text("CoReply Pro")
                                .font(.system(size: 32, weight: .black))
                                .foregroundColor(.white)
                            
                            Text("Unlock your ultimate texting assistant")
                                .font(.system(size: 15))
                                .foregroundColor(DesignConstants.Colors.textSecondary)
                        }
                        
                        // Features Checklist
                        VStack(alignment: .leading, spacing: 14) {
                            featureRow(icon: "bolt.fill", title: "Unlimited Generation", desc: "Remove the 20/day limit. Generate anytime, anywhere.")
                            featureRow(icon: "sparkles", title: "All 12 Texting Styles", desc: "Access Savage, Flirty, Malayalam, Manglish, and more.")
                            featureRow(icon: "brain.head.profile", title: "Custom Voice Cloning", desc: "Train your AI with your writing style using Auto-Learn.")
                            featureRow(icon: "bubble.left.and.bubble.right.fill", title: "Conversation Memory", desc: "AI remembers previous replies to maintain context.")
                        }
                        .padding()
                        .glassMorphism(cornerRadius: DesignConstants.Radius.medium)
                        .padding(.horizontal)
                        
                        // Products List
                        VStack(spacing: 12) {
                            if viewModel.products.isEmpty {
                                ProgressView()
                                    .tint(.white)
                                    .padding()
                            } else {
                                ForEach(viewModel.products) { product in
                                    let isSelected = selectedProductID == product.id
                                    
                                    Button {
                                        selectedProductID = product.id
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(product.displayName)
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(.white)
                                                Text(product.description)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(DesignConstants.Colors.textSecondary)
                                            }
                                            Spacer()
                                            
                                            VStack(alignment: .trailing, spacing: 4) {
                                                Text(viewModel.priceString(for: product))
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(.white)
                                                
                                                if product.id.contains("annual") {
                                                    Text("Save 40%")
                                                        .font(.system(size: 9, weight: .black))
                                                        .foregroundColor(.black)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 3)
                                                        .background(DesignConstants.Colors.premiumGold)
                                                        .cornerRadius(6)
                                                }
                                            }
                                        }
                                        .padding()
                                        .glassMorphism(
                                            cornerRadius: 14,
                                            opacity: isSelected ? 0.15 : 0.05,
                                            borderColor: isSelected ? DesignConstants.Colors.primaryAccent : Color.white.opacity(0.08)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Action Button
                        Button {
                            if let selected = viewModel.products.first(where: { $0.id == selectedProductID }) {
                                Task {
                                    await viewModel.purchase(selected)
                                    if viewModel.purchaseSuccess {
                                        dismiss()
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                if viewModel.isPurchasing {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Upgrade Now")
                                        .font(.system(size: 16, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(DesignConstants.Gradients.buttonGradient)
                            .cornerRadius(DesignConstants.Radius.medium)
                            .shadow(color: DesignConstants.Colors.primaryAccent.opacity(0.4), radius: 12, y: 4)
                        }
                        .disabled(selectedProductID.isEmpty || viewModel.isPurchasing)
                        .padding(.horizontal)
                        
                        // Error Display
                        if let error = viewModel.purchaseError {
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(DesignConstants.Colors.danger)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Bottom Actions
                        HStack(spacing: 24) {
                            Button("Restore Purchases") {
                                Task {
                                    await viewModel.restorePurchases()
                                }
                            }
                            
                            Text("•")
                            
                            Link("Privacy Policy", destination: URL(string: "https://coreply.ai/privacy")!)
                            
                            Text("•")
                            
                            Link("Terms of Use", destination: URL(string: "https://coreply.ai/terms")!)
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DesignConstants.Colors.textMuted)
                        .padding(.vertical, 12)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
        }
        .onAppear {
            if let firstProduct = viewModel.products.first {
                selectedProductID = firstProduct.id
            }
        }
        .onChange(of: viewModel.products) { newProducts in
            if selectedProductID.isEmpty, let first = newProducts.first {
                selectedProductID = first.id
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func featureRow(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(DesignConstants.Colors.primaryAccent)
                .frame(width: 36, height: 36)
                .background(DesignConstants.Colors.primaryAccent.opacity(0.12))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(DesignConstants.Colors.textSecondary)
            }
            Spacer()
        }
    }
}
