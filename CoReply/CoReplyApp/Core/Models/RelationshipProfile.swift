// RelationshipProfile.swift
// CoReply
//
// Profile store for relationship profiles.

import Foundation

@MainActor
public final class RelationshipProfileStore: ObservableObject {
    public static let shared = RelationshipProfileStore()
    
    @Published public var profiles: [RelationshipProfile] = []
    @Published public var activeProfile: RelationshipProfile?
    
    private let key = "relationship_profiles_list"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {
        loadProfiles()
    }
    
    // MARK: - Save & Load
    
    public func loadProfiles() {
        // Load from shared defaults
        guard let suite = UserDefaults(suiteName: AppConstants.appGroupID),
              let data = suite.data(forKey: key) else {
            // Load defaults if empty
            createDefaultProfiles()
            return
        }
        
        do {
            self.profiles = try decoder.decode([RelationshipProfile].self, from: data)
            
            // Resolve active profile
            let activeID = AppGroupStorage.shared.activeProfileID
            self.activeProfile = profiles.first { $0.id == activeID } ?? profiles.first
            if activeProfile != nil && activeID == nil {
                AppGroupStorage.shared.activeProfileID = activeProfile?.id
            }
        } catch {
            print("[RelationshipProfileStore] Load profiles failed: \(error.localizedDescription)")
            createDefaultProfiles()
        }
    }
    
    public func saveProfiles() {
        guard let suite = UserDefaults(suiteName: AppConstants.appGroupID) else { return }
        
        do {
            let data = try encoder.encode(profiles)
            suite.set(data, forKey: key)
        } catch {
            print("[RelationshipProfileStore] Save profiles failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - CRUD Operations
    
    public func addProfile(_ profile: RelationshipProfile) {
        profiles.append(profile)
        saveProfiles()
        
        // Sync to Supabase
        Task {
            try? await SupabaseService.shared.uploadProfile(profile)
        }
        
        // Set active if it's the first profile
        if profiles.count == 1 {
            setActiveProfile(profile)
        }
        objectWillChange.send()
    }
    
    public func updateProfile(_ profile: RelationshipProfile) {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        profiles[index] = profile
        saveProfiles()
        
        if activeProfile?.id == profile.id {
            activeProfile = profile
        }
        
        // Sync to Supabase
        Task {
            try? await SupabaseService.shared.uploadProfile(profile)
        }
        objectWillChange.send()
    }
    
    public func deleteProfile(_ profile: RelationshipProfile) {
        profiles.removeAll { $0.id == profile.id }
        saveProfiles()
        
        // Sync deletion to Supabase
        Task {
            try? await SupabaseService.shared.deleteProfile(id: profile.id)
        }
        
        // If deleted profile was active, set next one active
        if activeProfile?.id == profile.id {
            setActiveProfile(profiles.first)
        }
        objectWillChange.send()
    }
    
    public func setActiveProfile(_ profile: RelationshipProfile?) {
        self.activeProfile = profile
        AppGroupStorage.shared.activeProfileID = profile?.id
        objectWillChange.send()
        
        if let p = profile {
            var updated = p
            updated.lastUsedAt = Date()
            updateProfile(updated)
        }
    }
    
    // MARK: - Setup Helpers
    
    private func createDefaultProfiles() {
        let defaultProfiles = [
            RelationshipProfile(name: "Crush", relationshipType: .crush, conversationGoal: .expressInterest, notes: "Be playful, flirty, and build attraction!"),
            RelationshipProfile(name: "Best Friend", relationshipType: .bestFriend, conversationGoal: .keepConversationGoing, notes: "Use funny, sarcastic, and casual language."),
            RelationshipProfile(name: "Work Colleague", relationshipType: .colleague, conversationGoal: .beSerious, notes: "Keep it formal, polite, and brief.")
        ]
        
        self.profiles = defaultProfiles
        saveProfiles()
        setActiveProfile(defaultProfiles.first)
    }
}
