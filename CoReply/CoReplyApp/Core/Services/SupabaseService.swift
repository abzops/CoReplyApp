// SupabaseService.swift
// CoReply
//
// API service that handles authentication and persistence with Supabase.

import Foundation
import Supabase

public final class SupabaseService: @unchecked Sendable {
    public static let shared = SupabaseService()
    
    private var client: SupabaseClient?
    private let lock = NSLock()
    
    private init() {
        initializeClient()
    }
    
    /// Initializes or re-initializes the Supabase client using stored credentials.
    public func initializeClient() {
        lock.lock()
        defer { lock.unlock() }
        
        let keychain = KeychainService.shared
        let storedURL = keychain.load(key: AppConstants.Keys.supabaseURL) ?? ""
        let storedKey = keychain.load(key: AppConstants.Keys.supabaseAnonKey) ?? ""
        
        guard let url = URL(string: storedURL), !storedKey.isEmpty else {
            print("[SupabaseService] Client not initialized. Missing URL or Anon Key in Keychain.")
            self.client = nil
            return
        }
        
        self.client = SupabaseClient(supabaseURL: url, supabaseKey: storedKey)
        print("[SupabaseService] Client successfully initialized.")
    }
    
    private func getClient() throws -> SupabaseClient {
        lock.lock()
        defer { lock.unlock() }
        
        guard let client = self.client else {
            throw NSError(domain: "com.abhinand.coreply.supabase", code: 404, userInfo: [NSLocalizedDescriptionKey: "Supabase client not initialized. Configure API keys in Settings first."])
        }
        return client
    }
    
    // MARK: - Auth
    
    public func signInAnonymously() async throws {
        let client = try getClient()
        let session = try await client.auth.signInAnonymously()
        print("[SupabaseService] Signed in anonymously with user: \(session.user.id)")
        
        // Sync user profile immediately
        try await syncUserProfile(authUserID: session.user.id)
    }
    
    // MARK: - User Syncing
    
    private func syncUserProfile(authUserID: UUID) async throws {
        let client = try getClient()
        
        // Load user from local AppGroupStorage
        let localUser = await AppGroupStorage.shared.loadUser()
        let name = localUser?.name ?? "User"
        let ageRange = localUser?.ageRange.rawValue ?? CoUser.AgeRange.youngAdult.rawValue
        let language = localUser?.language.rawValue ?? CoUser.Language.english.rawValue
        let style = localUser?.communicationStyle.rawValue ?? CoUser.CommunicationStyle.casual.rawValue
        
        struct SupabaseUserUpdate: Encodable {
            let id: UUID
            let name: String
            let age_range: String
            let preferred_language: String
            let communication_style: String
            let subscription_tier: String
        }
        
        let update = SupabaseUserUpdate(
            id: authUserID,
            name: name,
            age_range: ageRange,
            preferred_language: language,
            communication_style: style,
            subscription_tier: await AppGroupStorage.shared.subscriptionTier.rawValue
        )
        
        // Insert or update user details
        try await client.database
            .from("users")
            .upsert(update)
            .execute()
        
        print("[SupabaseService] Synced user profile to remote database.")
    }
    
    // MARK: - Relationship Profiles CRUD
    
    public func uploadProfile(_ profile: RelationshipProfile) async throws {
        guard let client = try? getClient(),
              let userIDString = await AppGroupStorage.shared.userID,
              let userID = UUID(uuidString: userIDString) else { return }
        
        struct SupabaseProfile: Encodable {
            let id: UUID
            let user_id: UUID
            let name: String
            let relationship_type: String
            let conversation_goal: String
            let notes: String
            let favorite_styles: [String]
        }
        
        let dbProfile = SupabaseProfile(
            id: profile.id,
            user_id: userID,
            name: profile.name,
            relationship_type: profile.relationshipType.rawValue,
            conversation_goal: profile.conversationGoal.rawValue,
            notes: profile.notes,
            favorite_styles: profile.favoriteStyles.map { $0.rawValue }
        )
        
        try await client.database
            .from("profiles")
            .upsert(dbProfile)
            .execute()
    }
    
    public func deleteProfile(id: UUID) async throws {
        guard let client = try? getClient() else { return }
        
        try await client.database
            .from("profiles")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    // MARK: - Log Generation Events
    
    public func logGeneration(message: String, replies: [Reply], profileID: UUID?) async {
        guard let client = try? getClient(),
              let userIDString = await AppGroupStorage.shared.userID,
              let userID = UUID(uuidString: userIDString) else { return }
        
        do {
            struct SupabaseMessage: Encodable {
                let id: UUID
                let user_id: UUID
                let source_text: String
                let detected_language: String?
                let profile_id: UUID?
            }
            
            let messageID = UUID()
            let dbMessage = SupabaseMessage(
                id: messageID,
                user_id: userID,
                source_text: message,
                detected_language: await AppGroupStorage.shared.userLanguage,
                profile_id: profileID
            )
            
            // 1. Insert original message
            try await client.database
                .from("messages")
                .insert(dbMessage)
                .execute()
            
            // 2. Insert reply options
            struct SupabaseReply: Encodable {
                let id: UUID
                let message_id: UUID
                let generated_text: String
                let style: String
                let score_overall: Double
                let was_selected: Bool
            }
            
            let dbReplies = replies.map { r in
                SupabaseReply(
                    id: r.id,
                    message_id: messageID,
                    generated_text: r.text,
                    style: r.style.rawValue,
                    score_overall: r.score.overall,
                    was_selected: r.wasSelected
                )
            }
            
            try await client.database
                .from("replies")
                .insert(dbReplies)
                .execute()
                
            print("[SupabaseService] Generation logged successfully.")
        } catch {
            print("[SupabaseService] Failed to log generation to backend: \(error.localizedDescription)")
        }
    }
    
    public func logReplySelection(replyID: UUID) async {
        guard let client = try? getClient() else { return }
        
        do {
            struct SelectionUpdate: Encodable {
                let was_selected: Bool
            }
            
            try await client.database
                .from("replies")
                .update(SelectionUpdate(was_selected: true))
                .eq("id", value: replyID.uuidString)
                .execute()
            
            print("[SupabaseService] Logged reply selection.")
        } catch {
            print("[SupabaseService] Selection log failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Analytics
    
    public func trackEvent(name: String, metadata: [String: String] = [:]) async {
        guard let client = try? getClient(),
              let userIDString = await AppGroupStorage.shared.userID,
              let userID = UUID(uuidString: userIDString) else { return }
        
        struct SupabaseEvent: Encodable {
            let user_id: UUID
            let event_type: String
            let metadata: [String: String]
        }
        
        let event = SupabaseEvent(user_id: userID, event_type: name, metadata: metadata)
        
        do {
            try await client.database
                .from("usage_events")
                .insert(event)
                .execute()
        } catch {
            print("[SupabaseService] Analytics log failed: \(error.localizedDescription)")
        }
    }
}
