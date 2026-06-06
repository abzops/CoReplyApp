// ProfileManagerView.swift
// CoReply
//
// Screen for viewing, managing, and creating relationship context profiles.

import SwiftUI

struct ProfileManagerView: View {
    @StateObject private var viewModel = ProfileManagerViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                DesignConstants.Gradients.primaryBackground
                    .ignoresSafeArea()
                
                // Content
                if viewModel.profiles.isEmpty {
                    emptyStateView
                } else {
                    profilesListView
                }
            }
            .navigationTitle("Profiles")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.startNewProfile()
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
                editProfileSheet
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 64))
                .foregroundColor(DesignConstants.Colors.textMuted)
            
            Text("No Profiles Yet")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text("Create custom profiles to tailor AI reply tones for friends, crushes, family, and colleagues.")
                .font(.system(size: 14))
                .foregroundColor(DesignConstants.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                viewModel.startNewProfile()
            } label: {
                Text("Add First Profile")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(DesignConstants.Gradients.buttonGradient)
                    .cornerRadius(DesignConstants.Radius.medium)
            }
            .shadow(color: DesignConstants.Colors.primaryAccent.opacity(0.4), radius: 12, y: 4)
        }
        .padding()
    }
    
    // MARK: - Profiles List
    
    private var profilesListView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                ForEach(viewModel.profiles) { profile in
                    let isActive = viewModel.activeProfile?.id == profile.id
                    
                    HStack(spacing: 16) {
                        // Emoji Icon
                        Text(profile.relationshipType.emoji)
                            .font(.system(size: 32))
                            .frame(width: 56, height: 56)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Text details
                        VStack(alignment: .leading, spacing: 4) {
                            Text(profile.name)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 6) {
                                Text(profile.relationshipType.displayName)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(DesignConstants.Colors.primaryAccent)
                                
                                Text("•")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.3))
                                
                                Text(profile.conversationGoal.displayName)
                                    .font(.system(size: 11))
                                    .foregroundColor(DesignConstants.Colors.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Edit & Selection Actions
                        HStack(spacing: 12) {
                            Button {
                                viewModel.startEditing(profile)
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(width: 32, height: 32)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.setActive(profile)
                                }
                            } label: {
                                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22))
                                    .foregroundColor(isActive ? DesignConstants.Colors.primaryAccent : .white.opacity(0.3))
                            }
                        }
                    }
                    .padding()
                    .glassMorphism(
                        cornerRadius: DesignConstants.Radius.medium,
                        opacity: isActive ? 0.12 : 0.05,
                        borderColor: isActive ? DesignConstants.Colors.primaryAccent.opacity(0.5) : Color.white.opacity(0.08)
                    )
                    .contextMenu {
                        Button {
                            viewModel.startEditing(profile)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            viewModel.deleteProfile(profile)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Edit/Create Sheet
    
    private var editProfileSheet: some View {
        NavigationStack {
            ZStack {
                DesignConstants.Gradients.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: DesignConstants.Spacing.lg) {
                        // Section 1: Name
                        VStack(alignment: .leading, spacing: DesignConstants.Spacing.xs) {
                            Text("Name")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(DesignConstants.Colors.textSecondary)
                            
                            TextField("Enter name (e.g. Abhinand)", text: $viewModel.newProfileName)
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
                        .padding(.horizontal)
                        
                        // Section 2: Relationship Grid
                        VStack(alignment: .leading, spacing: DesignConstants.Spacing.xs) {
                            Text("Relationship Type")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(DesignConstants.Colors.textSecondary)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                                ForEach(RelationshipType.allCases) { type in
                                    let isSelected = viewModel.newRelationshipType == type
                                    
                                    Button {
                                        viewModel.newRelationshipType = type
                                    } label: {
                                        VStack(spacing: 6) {
                                            Text(type.emoji)
                                                .font(.system(size: 24))
                                            Text(type.displayName)
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(isSelected ? DesignConstants.Colors.primaryAccent.opacity(0.25) : Color.white.opacity(0.04))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isSelected ? DesignConstants.Colors.primaryAccent : Color.white.opacity(0.12), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Section 3: Goal Picker
                        VStack(alignment: .leading, spacing: DesignConstants.Spacing.xs) {
                            Text("Default Chat Goal")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(DesignConstants.Colors.textSecondary)
                            
                            Picker("Select Goal", selection: $viewModel.newConversationGoal) {
                                ForEach(ConversationGoal.allCases) { goal in
                                    Text("\(goal.emoji) \(goal.displayName)").tag(goal)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)
                        
                        // Section 4: Notes
                        VStack(alignment: .leading, spacing: DesignConstants.Spacing.xs) {
                            Text("Profile Notes (Context for AI)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(DesignConstants.Colors.textSecondary)
                            
                            TextEditor(text: $viewModel.newNotes)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .padding(8)
                                .frame(height: 100)
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
            .navigationTitle(viewModel.editingProfile == nil ? "Create Profile" : "Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.showingCreateSheet = false
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.saveProfile()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(DesignConstants.Colors.primaryAccent)
                    .disabled(viewModel.newProfileName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
