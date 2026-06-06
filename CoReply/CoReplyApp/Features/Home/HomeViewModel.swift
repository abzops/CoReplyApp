// HomeViewModel.swift
// CoReply
//
// View model for Home dashboard screen.

import SwiftUI
import Combine

@MainActor
public final class HomeViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published public var dailyRepliesUsed: Int = 0
    @Published public var dailyRepliesLimit: Int = AppConstants.Subscription.freeReplyLimit
    @Published public var isKeyboardEnabled: Bool = false
    @Published public var recentReplies: [ConversationMemoryEntry] = []
    @Published public var activeProfile: RelationshipProfile? = nil
    @Published public var currentTier: SubscriptionTier = .free
    @Published public var showingPaywall: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    public init() {
        // Observe AppGroupStorage changes
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshStats()
            }
            .store(in: &cancellables)
            
        // Observe RelationshipProfileStore changes
        RelationshipProfileStore.shared.objectWillChange
            .sink { [weak self] _ in
                self?.refreshStats()
            }
            .store(in: &cancellables)
            
        // Observe ConversationMemoryStore changes
        ConversationMemoryStore.shared.objectWillChange
            .sink { [weak self] _ in
                self?.refreshStats()
            }
            .store(in: &cancellables)
            
        refreshStats()
        checkKeyboardEnabled()
    }
    
    // MARK: - Refresh
    
    public func refreshStats() {
        let storage = AppGroupStorage.shared
        self.dailyRepliesUsed = storage.dailyReplyCount
        self.currentTier = storage.subscriptionTier
        self.dailyRepliesLimit = AppConstants.Subscription.freeReplyLimit
        self.activeProfile = RelationshipProfileStore.shared.activeProfile
        self.recentReplies = Array(ConversationMemoryStore.shared.entries.prefix(5))
    }
    
    // MARK: - Keyboard Status Check
    
    public func checkKeyboardEnabled() {
        guard let activeModes = UITextInputMode.activeInputModes as? [UITextInputMode] else {
            self.isKeyboardEnabled = false
            return
        }
        
        let hasKeyboard = activeModes.contains { mode in
            guard let identifier = mode.value(forKey: "identifier") as? String else { return false }
            return identifier.contains(AppConstants.keyboardBundleID)
        }
        
        self.isKeyboardEnabled = hasKeyboard
    }
    
    // MARK: - Computed Properties
    
    public var usagePercentage: Double {
        if currentTier != .free { return 1.0 }
        guard dailyRepliesLimit > 0 else { return 0.0 }
        return Double(dailyRepliesUsed) / Double(dailyRepliesLimit)
    }
    
    public var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = AppGroupStorage.shared.userName ?? "there"
        let wave = "👋"
        
        if hour < 12 {
            return "Good morning, \(name) \(wave)"
        } else if hour < 17 {
            return "Good afternoon, \(name) \(wave)"
        } else {
            return "Good evening, \(name) \(wave)"
        }
    }
}
