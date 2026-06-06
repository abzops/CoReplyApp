// Personality.swift
// CoReply
//
// Personality store class.

import Foundation

@MainActor
public final class PersonalityStore: ObservableObject {
    public static let shared = PersonalityStore()
    
    @Published public var personalities: [PersonalityProfile] = []
    @Published public var activePersonality: PersonalityProfile?
    @Published public var isAutoLearnEnabled = false
    
    private let customKey = "custom_personality_profiles_list"
    private let autoLearnKey = "auto_learn_enabled"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {
        self.isAutoLearnEnabled = UserDefaults.standard.bool(forKey: autoLearnKey)
        loadPersonalities()
    }
    
    // MARK: - Save & Load
    
    public func loadPersonalities() {
        var list = PersonalityProfile.builtIn
        
        // Load custom profiles
        if let data = UserDefaults.standard.data(forKey: customKey),
           let custom = try? decoder.decode([PersonalityProfile].self, from: data) {
            list.append(contentsOf: custom)
        }
        
        // Add auto-learn profile if enabled
        if isAutoLearnEnabled {
            if let autoProfile = loadAutoLearnedProfile() {
                list.append(autoProfile)
            }
        }
        
        self.personalities = list
        
        // Set active personality
        let activeID = AppGroupStorage.shared.activePersonalityID ?? "confident"
        self.activePersonality = personalities.first { $0.id == activeID } ?? personalities.first
        
        if activePersonality != nil && AppGroupStorage.shared.activePersonalityID == nil {
            AppGroupStorage.shared.activePersonalityID = activePersonality?.id
        }
    }
    
    public func saveCustomPersonalities(_ custom: [PersonalityProfile]) {
        if let encoded = try? encoder.encode(custom) {
            UserDefaults.standard.set(encoded, forKey: customKey)
        }
    }
    
    // MARK: - API Actions
    
    public func setActivePersonality(_ personality: PersonalityProfile) {
        self.activePersonality = personality
        AppGroupStorage.shared.activePersonalityID = personality.id
        objectWillChange.send()
        
        Task {
            await SupabaseService.shared.trackEvent(name: "active_personality_changed", metadata: ["id": personality.id])
        }
    }
    
    public func createCustomPersonality(name: String, emoji: String, description: String, traits: [String], style: String) {
        let newCustom = PersonalityProfile(
            id: UUID().uuidString,
            name: name,
            description: description,
            emoji: emoji,
            traits: traits,
            communicationStyle: style,
            isBuiltIn: false,
            isAutoLearned: false
        )
        
        var customList = getCustomListOnly()
        customList.append(newCustom)
        saveCustomPersonalities(customList)
        
        loadPersonalities()
        setActivePersonality(newCustom)
    }
    
    public func deleteCustomPersonality(_ personality: PersonalityProfile) {
        guard !personality.isBuiltIn && !personality.isAutoLearned else { return }
        
        var customList = getCustomListOnly()
        customList.removeAll { $0.id == personality.id }
        saveCustomPersonalities(customList)
        
        if activePersonality?.id == personality.id {
            setActivePersonality(personalities.first!)
        } else {
            loadPersonalities()
        }
    }
    
    public func toggleAutoLearn(_ enabled: Bool) {
        isAutoLearnEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: autoLearnKey)
        loadPersonalities()
        
        if !enabled && activePersonality?.isAutoLearned == true {
            setActivePersonality(personalities.first!)
        }
    }
    
    // MARK: - Auto Learn Generation
    
    public func recordReplySelection(style: ReplyStyle, text: String) {
        guard isAutoLearnEnabled else { return }
        
        var currentProfile = loadAutoLearnedProfile() ?? PersonalityProfile(
            id: "autolearn",
            name: "\(AppGroupStorage.shared.userName ?? "User") Mode",
            description: "Automatically learned from your style.",
            emoji: "🧠",
            traits: ["analytical"],
            communicationStyle: "Adapts dynamically",
            isBuiltIn: false,
            isAutoLearned: true
        )
        
        // Record style usage
        var styles = currentProfile.selectedReplyStyles
        styles[style.rawValue, default: 0] += 1
        currentProfile.selectedReplyStyles = styles
        
        // Simple average word length update
        let wordCount = text.components(separatedBy: .whitespaces).count
        let totalCount = styles.values.reduce(0, +)
        let currentAvg = currentProfile.averageReplyLength
        currentProfile.averageReplyLength = ((currentAvg * (totalCount - 1)) + wordCount) / max(1, totalCount)
        
        // Scan for emojis
        var existingEmojis = currentProfile.commonEmojis
        for char in text {
            if char.isEmojiPresentation {
                let s = String(char)
                if !existingEmojis.contains(s) {
                    existingEmojis.append(s)
                }
            }
        }
        currentProfile.commonEmojis = Array(existingEmojis.prefix(5))
        
        // Traits extraction
        var updatedTraits = currentProfile.traits
        let topStyle = styles.max(by: { $0.value < $1.value })?.key ?? "casual"
        if !updatedTraits.contains(topStyle) {
            updatedTraits.append(topStyle)
        }
        currentProfile.traits = Array(updatedTraits.suffix(4))
        
        // Save
        if let encoded = try? encoder.encode(currentProfile) {
            UserDefaults.standard.set(encoded, forKey: "autolearned_profile_data")
        }
        
        // Reload list to update view
        if activePersonality?.isAutoLearned == true {
            activePersonality = currentProfile
        }
        loadPersonalities()
    }
    
    // MARK: - Helpers
    
    private func getCustomListOnly() -> [PersonalityProfile] {
        guard let data = UserDefaults.standard.data(forKey: customKey),
              let list = try? decoder.decode([PersonalityProfile].self, from: data) else {
            return []
        }
        return list
    }
    
    private func loadAutoLearnedProfile() -> PersonalityProfile? {
        guard let data = UserDefaults.standard.data(forKey: "autolearned_profile_data") else {
            return PersonalityProfile(
                id: "autolearn",
                name: "\(AppGroupStorage.shared.userName ?? "User") Mode",
                description: "Automatically learned from your style.",
                emoji: "🧠",
                traits: ["casual"],
                communicationStyle: "Adapts dynamically",
                isBuiltIn: false,
                isAutoLearned: true
            )
        }
        return try? decoder.decode(PersonalityProfile.self, from: data)
    }
}

extension Character {
    var isEmojiPresentation: Bool {
        for scalar in unicodeScalars {
            if scalar.properties.isEmojiPresentation {
                return true
            }
        }
        return false
    }
}
