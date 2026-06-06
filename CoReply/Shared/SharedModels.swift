// SharedModels.swift
// CoReply
//
// Domain models shared across Main App and Keyboard Extension targets.

import Foundation
import SwiftUI

// MARK: - Subscription Tier
public enum SubscriptionTier: String, Codable, Sendable, CaseIterable {
    case free
    case pro
    case premium
    
    public var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        case .premium: return "Premium"
        }
    }
    
    public var replyLimit: Int {
        switch self {
        case .free: return 20
        case .pro, .premium: return Int.max
        }
    }
}

// MARK: - Reply Style
public enum ReplyStyle: String, Codable, Sendable, CaseIterable, Identifiable {
    case bestReply = "best_reply"
    case casual = "casual"
    case funny = "funny"
    case flirty = "flirty"
    case romantic = "romantic"
    case genZ = "gen_z"
    case professional = "professional"
    case savage = "savage"
    case malayalam = "malayalam"
    case manglish = "manglish"
    case continueConversation = "continue_conversation"
    case rewrite = "rewrite"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .bestReply: return "Best"
        case .casual: return "Casual"
        case .funny: return "Funny"
        case .flirty: return "Flirty"
        case .romantic: return "Romantic"
        case .genZ: return "Gen Z"
        case .professional: return "Professional"
        case .savage: return "Savage"
        case .malayalam: return "Malayalam"
        case .manglish: return "Manglish"
        case .continueConversation: return "Continue"
        case .rewrite: return "Rewrite"
        }
    }
    
    public var emoji: String {
        switch self {
        case .bestReply: return "⭐"
        case .casual: return "😎"
        case .funny: return "😂"
        case .flirty: return "😏"
        case .romantic: return "❤️"
        case .genZ: return "🔥"
        case .professional: return "💼"
        case .savage: return "😤"
        case .malayalam: return "🌴"
        case .manglish: return "🗣️"
        case .continueConversation: return "➡️"
        case .rewrite: return "✏️"
        }
    }
}

// MARK: - Relationship Type
public enum RelationshipType: String, Codable, Sendable, CaseIterable, Identifiable {
    case crush
    case girlfriend
    case boyfriend
    case friend
    case bestFriend = "best_friend"
    case family
    case colleague
    case acquaintance
    case stranger
    case exPartner = "ex_partner"
    case mentor
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .crush: return "Crush"
        case .girlfriend: return "Girlfriend"
        case .boyfriend: return "Boyfriend"
        case .friend: return "Friend"
        case .bestFriend: return "Best Friend"
        case .family: return "Family"
        case .colleague: return "Colleague"
        case .acquaintance: return "Acquaintance"
        case .stranger: return "Stranger"
        case .exPartner: return "Ex"
        case .mentor: return "Mentor"
        }
    }
    
    public var emoji: String {
        switch self {
        case .crush: return "👀"
        case .girlfriend: return "💖"
        case .boyfriend: return "💙"
        case .friend: return "👋"
        case .bestFriend: return "🤝"
        case .family: return "🏡"
        case .colleague: return "💼"
        case .acquaintance: return "💬"
        case .stranger: return "👤"
        case .exPartner: return "💔"
        case .mentor: return "🧠"
        }
    }
}

// MARK: - Conversation Goal
public enum ConversationGoal: String, Codable, Sendable, CaseIterable, Identifiable {
    case keepConversationGoing = "keep_going"
    case expressInterest = "express_interest"
    case bePlayful = "be_playful"
    case beSerious = "be_serious"
    case resolveConflict = "resolve_conflict"
    case expressAffection = "express_affection"
    case beNeutral = "be_neutral"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .keepConversationGoing: return "Keep Chat Flowing"
        case .expressInterest: return "Express Interest"
        case .bePlayful: return "Be Playful"
        case .beSerious: return "Be Serious"
        case .resolveConflict: return "Resolve Tension"
        case .expressAffection: return "Express Affection"
        case .beNeutral: return "Keep it Simple"
        }
    }
    
    public var emoji: String {
        switch self {
        case .keepConversationGoing: return "🔄"
        case .expressInterest: return "✨"
        case .bePlayful: return "😜"
        case .beSerious: return "🧐"
        case .resolveConflict: return "🕊️"
        case .expressAffection: return "❤️"
        case .beNeutral: return "💬"
        }
    }
}

// MARK: - Reply Score
public struct ReplyScore: Codable, Sendable, Equatable {
    public var overall: Double
    public var naturalness: Double
    public var relevance: Double
    public var engagement: Double
    
    public init(overall: Double, naturalness: Double, relevance: Double, engagement: Double) {
        self.overall = overall
        self.naturalness = naturalness
        self.relevance = relevance
        self.engagement = engagement
    }
}

// MARK: - Reply
public struct Reply: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public let text: String
    public let style: ReplyStyle
    public let score: ReplyScore
    public let createdAt: Date
    public var wasSelected: Bool
    
    public init(id: UUID = UUID(), text: String, style: ReplyStyle, score: ReplyScore, createdAt: Date = Date(), wasSelected: Bool = false) {
        self.id = id
        self.text = text
        self.style = style
        self.score = score
        self.createdAt = createdAt
        self.wasSelected = wasSelected
    }
}

// MARK: - Cached Reply Set
public struct CachedReplySet: Codable, Sendable, Equatable {
    public let sourceText: String
    public let replies: [Reply]
    public let generatedAt: Date
    public let profileID: UUID?
    
    public init(sourceText: String, replies: [Reply], generatedAt: Date = Date(), profileID: UUID?) {
        self.sourceText = sourceText
        self.replies = replies
        self.generatedAt = generatedAt
        self.profileID = profileID
    }
}

// MARK: - CoUser Model
public struct CoUser: Codable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var ageRange: AgeRange
    public var language: Language
    public var communicationStyle: CommunicationStyle
    public var subscriptionTier: SubscriptionTier
    public var createdAt: Date
    
    public init(id: UUID = UUID(), name: String, ageRange: AgeRange, language: Language, communicationStyle: CommunicationStyle, subscriptionTier: SubscriptionTier = .free, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.ageRange = ageRange
        self.language = language
        self.communicationStyle = communicationStyle
        self.subscriptionTier = subscriptionTier
        self.createdAt = createdAt
    }
    
    public enum AgeRange: String, Codable, CaseIterable, Sendable {
        case teen = "13-17"
        case youngAdult = "18-24"
        case adult = "25-34"
        case midAdult = "35-44"
        case senior = "45+"
        
        public var displayName: String { rawValue }
        
        public var emoji: String {
            switch self {
            case .teen: return "🎒"
            case .youngAdult: return "🎓"
            case .adult: return "💼"
            case .midAdult: return "🏡"
            case .senior: return "🌟"
            }
        }
        
        public var description: String {
            switch self {
            case .teen: return "School & social media trends"
            case .youngAdult: return "Uni, career, modern slang"
            case .adult: return "Work, social life, balanced"
            case .midAdult: return "Family, professional life"
            case .senior: return "Experienced, polite, direct"
            }
        }
    }
    
    public enum Language: String, Codable, CaseIterable, Sendable {
        case english = "English"
        case malayalam = "Malayalam"
        case manglish = "Manglish"
        case hindi = "Hindi"
        
        public var displayName: String { rawValue }
        
        public var flagEmoji: String {
            switch self {
            case .english: return "🇺🇸"
            case .malayalam: return "🌴"
            case .manglish: return "🗣️"
            case .hindi: return "🇮🇳"
            }
        }
        
        public var subtitle: String {
            switch self {
            case .english: return "Global communication"
            case .malayalam: return "കേരള തനിമയിൽ"
            case .manglish: return "Malayalam in English script"
            case .hindi: return "हिंदी संवाद"
            }
        }
    }
    
    public enum CommunicationStyle: String, Codable, CaseIterable, Sendable {
        case formal = "Formal"
        case casual = "Casual"
        case humorous = "Humorous"
        case romantic = "Romantic"
        case confident = "Confident"
        
        public var displayName: String { rawValue }
        
        public var emoji: String {
            switch self {
            case .formal: return "🎩"
            case .casual: return "😎"
            case .humorous: return "😂"
            case .romantic: return "💖"
            case .confident: return "💪"
            }
        }
        
        public var description: String {
            switch self {
            case .formal: return "Polite, well-structured, professional tone."
            case .casual: return "Relaxed, easygoing, everyday slang."
            case .humorous: return "Witty, playful, making others laugh."
            case .romantic: return "Expressive, thoughtful, affectionate."
            case .confident: return "Direct, self-assured, bold style."
            }
        }
        
        public var traits: [String] {
            switch self {
            case .formal: return ["polite", "structured", "respectful"]
            case .casual: return ["relaxed", "slang", "friendly"]
            case .humorous: return ["witty", "funny", "playful"]
            case .romantic: return ["affectionate", "warm", "caring"]
            case .confident: return ["direct", "bold", "assertive"]
            }
        }
    }
}

// MARK: - Relationship Profile
public struct RelationshipProfile: Codable, Identifiable, Sendable, Equatable {
    public var id: UUID
    public var name: String
    public var relationshipType: RelationshipType
    public var conversationGoal: ConversationGoal
    public var notes: String
    public var favoriteStyles: [ReplyStyle]
    public var createdAt: Date
    public var lastUsedAt: Date?
    
    public init(id: UUID = UUID(), name: String, relationshipType: RelationshipType, conversationGoal: ConversationGoal, notes: String, favoriteStyles: [ReplyStyle] = [], createdAt: Date = Date(), lastUsedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.relationshipType = relationshipType
        self.conversationGoal = conversationGoal
        self.notes = notes
        self.favoriteStyles = favoriteStyles
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }
}

// MARK: - Personality Profile
public struct PersonalityProfile: Codable, Identifiable, Sendable, Equatable {
    public var id: String
    public var name: String
    public var description: String
    public var emoji: String
    public var traits: [String]
    public var communicationStyle: String
    public var isBuiltIn: Bool
    public var isAutoLearned: Bool
    
    // Auto-learn statistics
    public var selectedReplyStyles: [String: Int]
    public var averageReplyLength: Int
    public var commonEmojis: [String]
    public var vocabularyHints: [String]
    
    public init(id: String, name: String, description: String, emoji: String, traits: [String], communicationStyle: String, isBuiltIn: Bool = false, isAutoLearned: Bool = false, selectedReplyStyles: [String : Int] = [:], averageReplyLength: Int = 10, commonEmojis: [String] = [], vocabularyHints: [String] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.emoji = emoji
        self.traits = traits
        self.communicationStyle = communicationStyle
        self.isBuiltIn = isBuiltIn
        self.isAutoLearned = isAutoLearned
        self.selectedReplyStyles = selectedReplyStyles
        self.averageReplyLength = averageReplyLength
        self.commonEmojis = commonEmojis
        self.vocabularyHints = vocabularyHints
    }
    
    public static var builtIn: [PersonalityProfile] {
        return [
            PersonalityProfile(id: "confident", name: "Confident", description: "Direct, self-assured, bold style.", emoji: "💪", traits: ["bold", "direct", "witty", "self-assured"], communicationStyle: "Assertive and direct"),
            PersonalityProfile(id: "funny", name: "Funny", description: "Witty, playful, making others laugh.", emoji: "😂", traits: ["witty", "playful", "sarcastic", "lighthearted"], communicationStyle: "Humorous and playful"),
            PersonalityProfile(id: "romantic", name: "Romantic", description: "Expressive, thoughtful, affectionate.", emoji: "❤️", traits: ["warm", "affectionate", "sincere", "expressive"], communicationStyle: "Heartfelt and warm"),
            PersonalityProfile(id: "mystery", name: "Mystery", description: "Charming but reserved and cool.", emoji: "🌙", traits: ["cool", "reserved", "intriguing", "concise"], communicationStyle: "Short and intriguing"),
            PersonalityProfile(id: "gentleman", name: "Gentleman", description: "Polite, chivalrous, well-structured.", emoji: "🎩", traits: ["polite", "thoughtful", "caring", "respectful"], communicationStyle: "Chivalrous and formal"),
            PersonalityProfile(id: "savage", name: "Savage", description: "Unapologetically direct and bold.", emoji: "🔥", traits: ["sarcastic", "unbothered", "clever", "blunt"], communicationStyle: "Sharp and witty"),
            PersonalityProfile(id: "malayalam_genz", name: "Malayalam Gen Z", description: "Modern Kerala texting vibe.", emoji: "🌴", traits: ["chill", "kerala-vibes", "local-slang", "witty"], communicationStyle: "Manglish-mixed casual")
        ]
    }
}
