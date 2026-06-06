// PersonalityView.swift
// CoReply
//
// View for selecting built-in communication styles or training a custom voice cloned model.

import SwiftUI

struct PersonalityView: View {
    @StateObject private var viewModel = PersonalityViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                DesignConstants.Gradients.primaryBackground
                    .ignoresSafeArea()
                
                // Ambient Glow
                Circle()
                    .fill(DesignConstants.Colors.secondaryAccent.opacity(0.06))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -100, y: 100)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignConstants.Spacing.lg) {
                        
                        // Active Personality Hero Card
                        if let active = viewModel.activePersonality {
                            activeHeroCard(active)
                        }
                        
                        // Auto Learn Switch
                        autoLearnToggleCard
                        
                        // Grid of available personalities
                        personalitiesSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Personality")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(DesignConstants.Colors.primaryAccent)
                            .clipShape(Circle())
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingCreateSheet) {
                createPersonalitySheet
            }
        }
    }
    
    // MARK: - Active Hero Card
    
    private func activeHeroCard(_ personality: PersonalityProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ACTIVE VOICE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(DesignConstants.Colors.primaryAccent)
                        .tracking(1)
                    
                    Text(personality.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                Text(personality.emoji)
                    .font(.system(size: 44))
                    .frame(width: 72, height: 72)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            
            Text(personality.description)
                .font(.system(size: 14))
                .foregroundColor(DesignConstants.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Traits chips
            HStack(spacing: 6) {
                ForEach(personality.traits, id: \.self) { trait in
                    Text("#\(trait)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(DesignConstants.Colors.primaryAccent.opacity(0.25))
                        .cornerRadius(8)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .glassMorphism(
            cornerRadius: DesignConstants.Radius.medium,
            opacity: 0.15,
            borderColor: DesignConstants.Colors.primaryAccent.opacity(0.5)
        )
        .padding(.horizontal)
        .shadow(color: DesignConstants.Colors.primaryAccent.opacity(0.15), radius: 15, y: 6)
    }
    
    // MARK: - Auto-Learn Card
    
    private var autoLearnToggleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 28))
                    .foregroundColor(DesignConstants.Colors.primaryAccent)
                    .frame(width: 48, height: 48)
                    .background(DesignConstants.Colors.primaryAccent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Auto-Learn Mode")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Automatically learn your vocabulary, emojis, and reply length to generate a personalized clone of your voice.")
                        .font(.system(size: 12))
                        .foregroundColor(DesignConstants.Colors.textSecondary)
                        .lineSpacing(2)
                }
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { viewModel.isAutoLearnEnabled },
                    set: { viewModel.toggleAutoLearn($0) }
                ))
                .labelsHidden()
                .tint(DesignConstants.Colors.primaryAccent)
            }
            
            if viewModel.isAutoLearnEnabled {
                Divider().background(Color.white.opacity(0.1))
                
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 12))
                        .foregroundColor(DesignConstants.Colors.success)
                    
                    Text("Cloned voice profile will update dynamically on selection events.")
                        .font(.system(size: 11))
                        .foregroundColor(DesignConstants.Colors.textSecondary)
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .glassMorphism(cornerRadius: DesignConstants.Radius.medium)
        .padding(.horizontal)
    }
    
    // MARK: - Personalities Grid Section
    
    private var personalitiesSection: some View {
        VStack(alignment: .leading, spacing: DesignConstants.Spacing.sm) {
            Text("Voice Catalog")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(viewModel.personalities) { persona in
                    let isActive = viewModel.activePersonality?.id == persona.id
                    
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.setActive(persona)
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(persona.emoji)
                                    .font(.system(size: 24))
                                Spacer()
                                if isActive {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(DesignConstants.Colors.primaryAccent)
                                        .font(.system(size: 14))
                                }
                            }
                            
                            Text(persona.name)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Text(persona.description)
                                .font(.system(size: 11))
                                .foregroundColor(DesignConstants.Colors.textSecondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .frame(height: 32, alignment: .top)
                        }
                        .padding()
                        .glassMorphism(
                            cornerRadius: DesignConstants.Radius.medium,
                            opacity: isActive ? 0.12 : 0.05,
                            borderColor: isActive ? DesignConstants.Colors.primaryAccent.opacity(0.5) : Color.white.opacity(0.08)
                        )
                        .contextMenu {
                            if !persona.isBuiltIn && !persona.isAutoLearned {
                                Button(role: .destructive) {
                                    viewModel.deletePersonality(persona)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Custom Voice Creator Sheet
    
    private var createPersonalitySheet: some View {
        NavigationStack {
            ZStack {
                DesignConstants.Gradients.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: DesignConstants.Spacing.lg) {
                        
                        // Avatar Emoji & Name
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Emoji")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(DesignConstants.Colors.textSecondary)
                                
                                TextField("🎭", text: $viewModel.newEmoji)
                                    .font(.system(size: 24))
                                    .padding(.vertical, 8)
                                    .frame(width: 56, height: 56)
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(12)
                                    .multilineTextAlignment(.center)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Voice Name")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(DesignConstants.Colors.textSecondary)
                                
                                TextField("e.g. Mystery Lover", text: $viewModel.newName)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Description
                        VStack(alignment: .leading, spacing: DesignConstants.Spacing.xs) {
                            Text("Description")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(DesignConstants.Colors.textSecondary)
                            
                            TextField("Describe how this voice acts", text: $viewModel.newDescription)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)
                        
                        // Traits
                        VStack(alignment: .leading, spacing: DesignConstants.Spacing.xs) {
                            Text("Traits (comma separated)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(DesignConstants.Colors.textSecondary)
                            
                            TextField("e.g. sarcastic, mysterious, warm", text: $viewModel.newTraits)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)
                        
                        // Communication Style Description
                        VStack(alignment: .leading, spacing: DesignConstants.Spacing.xs) {
                            Text("Communication Style Directives")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(DesignConstants.Colors.textSecondary)
                            
                            TextEditor(text: $viewModel.newStyle)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .padding(8)
                                .frame(height: 80)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(12)
                                .scrollContentBackground(.hidden)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Create Custom Voice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.showingCreateSheet = false
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        viewModel.createPersonality()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(DesignConstants.Colors.primaryAccent)
                    .disabled(viewModel.newName.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.newDescription.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
