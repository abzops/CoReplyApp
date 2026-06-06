// KeyboardViewModel.swift
// CoReplyKeyboard
//
// View model managing keyboard layout state, clipboard checks, and proxy actions.

import SwiftUI
import Combine

@MainActor
public final class KeyboardViewModel: ObservableObject {
    public static let preferredHeight: CGFloat = 320.0
    
    // MARK: - Published State
    
    @Published public var replies: [Reply] = []
    @Published public var isLoading: Bool = false
    @Published public var error: String? = nil
    @Published public var clipboardText: String = ""
    @Published public var selectedStyle: ReplyStyle = .bestReply
    @Published public var activeProfile: RelationshipProfile? = nil
    @Published public var activePersonality: PersonalityProfile? = nil
    @Published public var hasFullAccess: Bool = false
    @Published public var dailyLimitReached: Bool = false
    @Published public var repliesRemaining: Int = AppConstants.Subscription.freeReplyLimit
    @Published public var preferredKeyboardHeight: CGFloat = preferredHeight
    
    // MARK: - Dependencies
    
    private weak var inputViewController: UIInputViewController?
    private let aiService = KeyboardAIService()
    private let clipboardService = ClipboardService.shared
    private let storage = AppGroupStorage.shared
    
    private var lastCheckedChangeCount: Int = -1
    
    // MARK: - Init
    
    public init(inputViewController: UIInputViewController) {
        self.inputViewController = inputViewController
        self.hasFullAccess = clipboardService.hasFullAccess()
        
        loadActiveProfileAndPersonality()
        setupClipboardWatcher()
    }
    
    // MARK: - Lifecycle Hooks
    
    public func onKeyboardAppear(proxy: UITextDocumentProxy) {
        loadActiveProfileAndPersonality()
        checkLimit()
        
        // Sync clipboard immediately on opening
        if hasFullAccess {
            clipboardService.startPolling()
            clipboardService.syncCurrentClipboard()
        } else {
            self.error = "Please enable 'Allow Full Access' in CoReply keyboard settings to read the clipboard."
        }
    }
    
    public func onKeyboardDisappear() {
        clipboardService.stopPolling()
    }
    
    public func textDidChange(proxy: UITextDocumentProxy) {
        // no-op by default or custom autocomplete triggers
    }
    
    // MARK: - Clipboard Setup
    
    private func setupClipboardWatcher() {
        clipboardService.onNewClipboardContent = { [weak self] text in
            guard let self = self else { return }
            self.clipboardText = text
            
            // Check cache before calling AI
            if let cached = self.storage.cachedReplies, cached.sourceText == text {
                self.replies = cached.replies
                self.error = nil
            } else {
                // Auto trigger generation for new clipboard
                Task {
                    await self.generateReplies()
                }
            }
        }
    }
    
    // MARK: - Load Configurations
    
    public func loadActiveProfileAndPersonality() {
        // Since we are inside the Extension target, we read profiles directly from suite
        let activeID = storage.activeProfileID
        
        // Profile parsing
        if let suite = UserDefaults(suiteName: AppConstants.appGroupID),
           let data = suite.data(forKey: "relationship_profiles_list"),
           let profiles = try? JSONDecoder().decode([RelationshipProfile].self, from: data) {
            self.activeProfile = profiles.first { $0.id == activeID } ?? profiles.first
        }
        
        // Personality parsing
        let activePersID = storage.activePersonalityID ?? "confident"
        self.activePersonality = PersonalityProfile.builtIn.first { $0.id == activePersID }
        
        // Fallback for custom personalities from UserDefaults standard if shared suite isn't ready
        if activePersonality == nil {
            self.activePersonality = PersonalityProfile.builtIn.first
        }
    }
    
    // MARK: - Check Generation Limits
    
    private func checkLimit() {
        self.dailyLimitReached = !storage.canGenerateReply()
        self.repliesRemaining = storage.remainingReplies()
    }
    
    // MARK: - Generate Replies
    
    public func generateReplies() async {
        guard !clipboardText.isEmpty else {
            self.error = "Copy a message in Snapchat or another app first."
            return
        }
        
        checkLimit()
        guard !dailyLimitReached else {
            self.error = "Daily reply limit reached. Open CoReply App to upgrade to Pro."
            return
        }
        
        isLoading = true
        error = nil
        replies = []
        
        let profile = activeProfile ?? RelationshipProfile(name: "Stranger", relationshipType: .stranger, conversationGoal: .beNeutral, notes: "")
        
        do {
            let result = try await aiService.generateReplies(
                message: clipboardText,
                style: selectedStyle,
                relationshipType: profile.relationshipType,
                personalityProfile: activePersonality,
                goal: profile.conversationGoal,
                userName: storage.userName ?? "User"
            )
            
            self.replies = result
            
            // Cache locally
            let replySet = CachedReplySet(sourceText: clipboardText, replies: result, profileID: profile.id)
            storage.cachedReplies = replySet
            
            // Increment local usages
            storage.incrementDailyReplyCount()
            checkLimit()
            
            // Log to remote db asynchronously
            Task {
                await SupabaseService.shared.logGeneration(message: clipboardText, replies: result, profileID: profile.id)
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Selection & Text Insertion
    
    public func insertReply(_ reply: Reply) {
        guard let proxy = inputViewController?.textDocumentProxy else { return }
        
        // Insert into text input field
        proxy.insertText(reply.text)
        
        // Record selection locally for Auto-Learn and logging
        Task {
            // Update memory list inside shared defaults
            let source = clipboardText
            let style = reply.style
            let pID = activeProfile?.id
            
            // Since ConversationMemoryStore is @MainActor, we run it on MainActor
            ConversationMemoryStore.shared.addEntry(sourceText: source, selectedReply: reply.text, style: style, profileID: pID)
            
            // Sync selection to backend db
            await SupabaseService.shared.logReplySelection(replyID: reply.id)
        }
        
        // Triggers brief selection animation or sound if needed
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    public func selectStyle(_ style: ReplyStyle) {
        guard selectedStyle != style else { return }
        selectedStyle = style
        
        if !clipboardText.isEmpty {
            Task {
                await generateReplies()
            }
        }
    }
    
    public func advanceToNextKeyboard() {
        inputViewController?.advanceToNextInputMode()
    }
}
