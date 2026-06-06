// ConversationMemory.swift
// CoReply
//
// Persistent tracking of generated replies, style choices, and selected outputs.

import Foundation

public struct ConversationMemoryEntry: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public let sourceText: String
    public let selectedReply: String
    public let style: ReplyStyle
    public let profileID: UUID?
    public let timestamp: Date
    
    public init(id: UUID = UUID(), sourceText: String, selectedReply: String, style: ReplyStyle, profileID: UUID?, timestamp: Date = Date()) {
        self.id = id
        self.sourceText = sourceText
        self.selectedReply = selectedReply
        self.style = style
        self.profileID = profileID
        self.timestamp = timestamp
    }
}

@MainActor
public final class ConversationMemoryStore: ObservableObject {
    public static let shared = ConversationMemoryStore()
    
    @Published public var entries: [ConversationMemoryEntry] = []
    
    private let storageKey = "conversation_memory_entries"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {
        loadEntries()
    }
    
    // MARK: - Save & Load
    
    public func loadEntries() {
        guard let suite = UserDefaults(suiteName: AppConstants.appGroupID),
              let data = suite.data(forKey: storageKey) else {
            return
        }
        
        do {
            self.entries = try decoder.decode([ConversationMemoryEntry].self, from: data)
        } catch {
            print("[ConversationMemoryStore] Load failed: \(error.localizedDescription)")
        }
    }
    
    public func saveEntries() {
        guard let suite = UserDefaults(suiteName: AppConstants.appGroupID) else { return }
        
        do {
            let data = try encoder.encode(entries)
            suite.set(data, forKey: storageKey)
        } catch {
            print("[ConversationMemoryStore] Save failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - API Actions
    
    public func addEntry(sourceText: String, selectedReply: String, style: ReplyStyle, profileID: UUID?) {
        let entry = ConversationMemoryEntry(
            sourceText: sourceText,
            selectedReply: selectedReply,
            style: style,
            profileID: profileID
        )
        
        // Prepend to show newest first
        entries.insert(entry, at: 0)
        
        // Cap size to 50
        if entries.count > 50 {
            entries = Array(entries.prefix(50))
        }
        
        saveEntries()
        objectWillChange.send()
        
        // Also trigger personality engine auto-learn
        PersonalityStore.shared.recordReplySelection(style: style, text: selectedReply)
    }
    
    public func entriesFor(profileID: UUID?) -> [ConversationMemoryEntry] {
        return entries.filter { $0.profileID == profileID }
    }
    
    public func clearAll() {
        entries.removeAll()
        saveEntries()
        objectWillChange.send()
    }
}
