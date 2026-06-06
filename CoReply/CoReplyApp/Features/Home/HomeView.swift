// HomeView.swift
// CoReply
//
// Dashboard container and main landing interface for CoReply AI.

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedTab = 0
    @State private var animateRing = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Dashboard
            dashboardTab
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2.fill")
                }
                .tag(0)
            
            // Tab 2: Profiles
            ProfileManagerView()
                .tabItem {
                    Label("Profiles", systemImage: "person.2.fill")
                }
                .tag(1)
            
            // Tab 3: Personality
            PersonalityView()
                .tabItem {
                    Label("Personality", systemImage: "brain.head.profile")
                }
                .tag(2)
            
            // Tab 4: Settings
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(DesignConstants.Colors.primaryAccent)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $viewModel.showingPaywall) {
            SubscriptionView()
        }
    }
    
    // MARK: - Dashboard Tab View
    
    private var dashboardTab: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                DesignConstants.Gradients.primaryBackground
                    .ignoresSafeArea()
                
                // Ambient Glows
                Circle()
                    .fill(DesignConstants.Colors.primaryAccent.opacity(0.12))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -80, y: -150)
                
                Circle()
                    .fill(DesignConstants.Colors.secondaryAccent.opacity(0.08))
                    .frame(width: 250, height: 250)
                    .blur(radius: 60)
                    .offset(x: 100, y: 150)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignConstants.Spacing.lg) {
                        
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: DesignConstants.Spacing.xs) {
                                Text(viewModel.greeting)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(DesignConstants.Colors.textPrimary)
                                
                                Text("Ready to generate replies")
                                    .font(.system(size: 14))
                                    .foregroundColor(DesignConstants.Colors.textSecondary)
                            }
                            Spacer()
                            
                            // Pro Badge
                            if viewModel.currentTier != .free {
                                Text("PRO")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(DesignConstants.Gradients.premiumGradient)
                                    .cornerRadius(8)
                            } else {
                                Button {
                                    viewModel.showingPaywall = true
                                } label: {
                                    Text("Upgrade")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(DesignConstants.Gradients.buttonGradient)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Circular Usage Ring Card
                        usageCard
                        
                        // Keyboard Setup Card
                        keyboardStatusCard
                        
                        // Quick Profiles
                        quickProfilesSection
                        
                        // Recent Activities
                        recentRepliesSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: "keyboard")
                            .foregroundColor(DesignConstants.Colors.primaryAccent)
                        Text("CoReply AI")
                            .font(.system(size: 18, weight: .extrabold))
                            .foregroundColor(.white)
                    }
                }
            }
            .onAppear {
                viewModel.refreshStats()
                viewModel.checkKeyboardEnabled()
                withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                    animateRing = true
                }
            }
        }
    }
    
    // MARK: - Usage Circular Card
    
    private var usageCard: some View {
        VStack(spacing: DesignConstants.Spacing.md) {
            HStack(spacing: 24) {
                // Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.06), lineWidth: 10)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0.0, to: animateRing ? CGFloat(viewModel.usagePercentage) : 0.0)
                        .stroke(
                            DesignConstants.Gradients.buttonGradient,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(Angle(degrees: -90))
                    
                    VStack(spacing: 0) {
                        if viewModel.currentTier == .free {
                            Text("\(viewModel.dailyRepliesLimit - viewModel.dailyRepliesUsed)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            Text("left")
                                .font(.system(size: 11))
                                .foregroundColor(DesignConstants.Colors.textSecondary)
                        } else {
                            Image(systemName: "infinity")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(DesignConstants.Colors.premiumGold)
                        }
                    }
                }
                
                // Text details
                VStack(alignment: .leading, spacing: DesignConstants.Spacing.xs) {
                    Text("Daily Generations")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if viewModel.currentTier == .free {
                        Text("\(viewModel.dailyRepliesUsed) of \(viewModel.dailyRepliesLimit) replies used today.")
                            .font(.system(size: 13))
                            .foregroundColor(DesignConstants.Colors.textSecondary)
                    } else {
                        Text("Unlimited replies active with CoReply Pro.")
                            .font(.system(size: 13))
                            .foregroundColor(DesignConstants.Colors.textSecondary)
                    }
                    
                    Text("Resets at midnight local time.")
                        .font(.system(size: 11))
                        .foregroundColor(DesignConstants.Colors.textMuted)
                }
                
                Spacer()
            }
            .padding()
            .glassMorphism(cornerRadius: DesignConstants.Radius.medium)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Keyboard Status Card
    
    private var keyboardStatusCard: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(viewModel.isKeyboardEnabled ? DesignConstants.Colors.success.opacity(0.15) : DesignConstants.Colors.warning.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: viewModel.isKeyboardEnabled ? "keyboard" : "exclamationmark.triangle.fill")
                        .foregroundColor(viewModel.isKeyboardEnabled ? DesignConstants.Colors.success : DesignConstants.Colors.warning)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.isKeyboardEnabled ? "Keyboard Active" : "Setup Required")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                
                Text(viewModel.isKeyboardEnabled ? "CoReply Keyboard is enabled and ready to use." : "Enable keyboard in settings for instant copy-paste replies.")
                    .font(.system(size: 12))
                    .foregroundColor(DesignConstants.Colors.textSecondary)
            }
            
            Spacer()
            
            if !viewModel.isKeyboardEnabled {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .glassMorphism(cornerRadius: DesignConstants.Radius.medium)
        .padding(.horizontal)
    }
    
    // MARK: - Quick Profiles Row
    
    private var quickProfilesSection: some View {
        VStack(alignment: .leading, spacing: DesignConstants.Spacing.sm) {
            HStack {
                Text("Relationship Profiles")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button {
                    selectedTab = 1 // Go to Profiles tab
                } label: {
                    Text("Manage")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(DesignConstants.Colors.primaryAccent)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(RelationshipProfileStore.shared.profiles) { profile in
                        let isActive = viewModel.activeProfile?.id == profile.id
                        
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                RelationshipProfileStore.shared.setActiveProfile(profile)
                                viewModel.refreshStats()
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(profile.relationshipType.emoji)
                                        .font(.system(size: 24))
                                    Spacer()
                                    if isActive {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(DesignConstants.Colors.primaryAccent)
                                            .font(.system(size: 14))
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profile.name)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                    Text(profile.relationshipType.displayName)
                                        .font(.system(size: 11))
                                        .foregroundColor(DesignConstants.Colors.textSecondary)
                                }
                            }
                            .frame(width: 110, height: 90)
                            .padding()
                            .glassMorphism(
                                cornerRadius: DesignConstants.Radius.medium,
                                opacity: isActive ? 0.15 : 0.05,
                                borderColor: isActive ? DesignConstants.Colors.primaryAccent.opacity(0.6) : Color.white.opacity(0.08)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Recent Replies List
    
    private var recentRepliesSection: some View {
        VStack(alignment: .leading, spacing: DesignConstants.Spacing.sm) {
            Text("Recent Generated Replies")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal)
            
            if viewModel.recentReplies.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 32))
                        .foregroundColor(DesignConstants.Colors.textMuted)
                    
                    Text("No replies generated yet")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Start typing in Snapchat using CoReply Keyboard to generate suggestions.")
                        .font(.system(size: 12))
                        .foregroundColor(DesignConstants.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .glassMorphism(cornerRadius: DesignConstants.Radius.medium)
                .padding(.horizontal)
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.recentReplies) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(entry.style.emoji)
                                Text(entry.style.displayName)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(DesignConstants.Colors.primaryAccent)
                                
                                Spacer()
                                
                                Text(entry.timestamp, style: .time)
                                    .font(.system(size: 11))
                                    .foregroundColor(DesignConstants.Colors.textMuted)
                            }
                            
                            Text("\"\(entry.sourceText)\"")
                                .font(.system(size: 12, weight: .light))
                                .foregroundColor(DesignConstants.Colors.textSecondary)
                                .lineLimit(1)
                                .italic()
                            
                            Text(entry.selectedReply)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(2)
                        }
                        .padding()
                        .glassMorphism(cornerRadius: 12)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
