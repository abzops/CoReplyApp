// ProfileManagerViewModel.swift
// CoReply
//
// View model managing CRUD operations for user's relationship profiles.

import SwiftUI
import Combine

@MainActor
public final class ProfileManagerViewModel: ObservableObject {
    @Published public var profiles: [RelationshipProfile] = []
    @Published public var showingCreateSheet = false
    @Published public var editingProfile: RelationshipProfile? = nil
    
    // Form Inputs
    @Published public var newProfileName = ""
    @Published public var newRelationshipType: RelationshipType = .crush
    @Published public var newConversationGoal: ConversationGoal = .keepConversationGoing
    @Published public var newNotes = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        // Observe changes from shared profile store
        RelationshipProfileStore.shared.objectWillChange
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
            
        refresh()
    }
    
    public func refresh() {
        self.profiles = RelationshipProfileStore.shared.profiles
    }
    
    public var activeProfile: RelationshipProfile? {
        RelationshipProfileStore.shared.activeProfile
    }
    
    public func startEditing(_ profile: RelationshipProfile) {
        self.editingProfile = profile
        self.newProfileName = profile.name
        self.newRelationshipType = profile.relationshipType
        self.newConversationGoal = profile.conversationGoal
        self.newNotes = profile.notes
        self.showingCreateSheet = true
    }
    
    public func startNewProfile() {
        self.editingProfile = nil
        self.newProfileName = ""
        self.newRelationshipType = .crush
        self.newConversationGoal = .keepConversationGoing
        self.newNotes = ""
        self.showingCreateSheet = true
    }
    
    public func saveProfile() {
        let trimmedName = newProfileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        if let existing = editingProfile {
            let updated = RelationshipProfile(
                id: existing.id,
                name: trimmedName,
                relationshipType: newRelationshipType,
                conversationGoal: newConversationGoal,
                notes: newNotes,
                favoriteStyles: existing.favoriteStyles,
                createdAt: existing.createdAt,
                lastUsedAt: existing.lastUsedAt
            )
            RelationshipProfileStore.shared.updateProfile(updated)
        } else {
            let newProfile = RelationshipProfile(
                name: trimmedName,
                relationshipType: newRelationshipType,
                conversationGoal: newConversationGoal,
                notes: newNotes
            )
            RelationshipProfileStore.shared.addProfile(newProfile)
        }
        
        showingCreateSheet = false
    }
    
    public func deleteProfile(_ profile: RelationshipProfile) {
        RelationshipProfileStore.shared.deleteProfile(profile)
    }
    
    public func setActive(_ profile: RelationshipProfile) {
        RelationshipProfileStore.shared.setActiveProfile(profile)
    }
}
