// SettingsViewModel.swift
// CoReply
//
// View model managing secure storage configuration and local database backups.

import SwiftUI
import Combine

@MainActor
public final class SettingsViewModel: ObservableObject {
    @Published public var openAIKey = ""
    @Published public var supabaseURL = ""
    @Published public var supabaseAnonKey = ""
    @Published public var isSaving = false
    @Published public var saveSuccess = false
    @Published public var cloudSyncEnabled = false
    @Published public var showingDeleteConfirm = false
    
    public init() {
        loadKeys()
    }
    
    public func loadKeys() {
        let keychain = KeychainService.shared
        self.openAIKey = keychain.load(key: AppConstants.Keys.openAIKey) ?? ""
        self.supabaseURL = keychain.load(key: AppConstants.Keys.supabaseURL) ?? ""
        self.supabaseAnonKey = keychain.load(key: AppConstants.Keys.supabaseAnonKey) ?? ""
        
        self.cloudSyncEnabled = UserDefaults.standard.bool(forKey: "cloud_sync_enabled")
    }
    
    public func saveAPIKeys() {
        isSaving = true
        saveSuccess = false
        
        let keychain = KeychainService.shared
        let trimmedKey = openAIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUrl = supabaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAnon = supabaseAnonKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Save to Keychain
        keychain.save(key: AppConstants.Keys.openAIKey, value: trimmedKey)
        keychain.save(key: AppConstants.Keys.supabaseURL, value: trimmedUrl)
        keychain.save(key: AppConstants.Keys.supabaseAnonKey, value: trimmedAnon)
        
        // Update flags in Shared Defaults
        AppGroupStorage.shared.isOpenAIKeyStored = !trimmedKey.isEmpty
        UserDefaults.standard.set(cloudSyncEnabled, forKey: "cloud_sync_enabled")
        
        // Reinitialize client
        SupabaseService.shared.initializeClient()
        
        isSaving = false
        saveSuccess = true
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        // Auto-dismiss success status in 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.saveSuccess = false
        }
    }
    
    public func clearAPIKeys() {
        let keychain = KeychainService.shared
        keychain.clearAll()
        AppGroupStorage.shared.isOpenAIKeyStored = false
        
        self.openAIKey = ""
        self.supabaseURL = ""
        self.supabaseAnonKey = ""
        
        SupabaseService.shared.initializeClient()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    public func deleteAllData() {
        // Clear all persistent scopes
        KeychainService.shared.clearAll()
        AppGroupStorage.shared.clearAll()
        ConversationMemoryStore.shared.clearAll()
        
        // Clear Standard UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        
        loadKeys()
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    public func openSystemKeyboardSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    
    public var maskedOpenAIKey: String {
        guard !openAIKey.isEmpty else { return "" }
        if openAIKey.hasPrefix("sk-") {
            let visible = String(openAIKey.prefix(7)) // "sk-...xxxx"
            let suffix = String(openAIKey.suffix(4))
            return "\(visible)..." + suffix
        }
        return "Key Configured"
    }
}
