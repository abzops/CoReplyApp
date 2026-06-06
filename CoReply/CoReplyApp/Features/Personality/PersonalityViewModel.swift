// PersonalityViewModel.swift
// CoReply
//
// View model that tracks active texting personas and handles custom profiles.

import SwiftUI
import Combine

@MainActor
public final class PersonalityViewModel: ObservableObject {
    @Published public var personalities: [PersonalityProfile] = []
    @Published public var activePersonality: PersonalityProfile?
    @Published public var isAutoLearnEnabled = false
    @Published public var showingCreateSheet = false
    
    // Form Inputs
    @Published public var newName = ""
    @Published public var newEmoji = "🎭"
    @Published public var newDescription = ""
    @Published public var newTraits = ""
    @Published public var newStyle = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        PersonalityStore.shared.objectWillChange
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
            
        refresh()
    }
    
    public func refresh() {
        self.personalities = PersonalityStore.shared.personalities
        self.activePersonality = PersonalityStore.shared.activePersonality
        self.isAutoLearnEnabled = PersonalityStore.shared.isAutoLearnEnabled
    }
    
    public func setActive(_ personality: PersonalityProfile) {
        PersonalityStore.shared.setActivePersonality(personality)
    }
    
    public func toggleAutoLearn(_ enabled: Bool) {
        PersonalityStore.shared.toggleAutoLearn(enabled)
    }
    
    public func createPersonality() {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDesc = newDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty && !trimmedDesc.isEmpty else { return }
        
        // Parse traits from comma separated string
        let traitsArray = newTraits
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        let finalStyle = newStyle.trimmingCharacters(in: .whitespacesAndNewlines)
        
        PersonalityStore.shared.createCustomPersonality(
            name: trimmedName,
            emoji: newEmoji.isEmpty ? "🎭" : newEmoji,
            description: trimmedDesc,
            traits: traitsArray.isEmpty ? ["custom"] : traitsArray,
            style: finalStyle.isEmpty ? "Custom style" : finalStyle
        )
        
        showingCreateSheet = false
    }
    
    public func deletePersonality(_ personality: PersonalityProfile) {
        PersonalityStore.shared.deleteCustomPersonality(personality)
    }
}
