// KeyboardAIService.swift
// CoReplyKeyboard
//
// Lightweight OpenAI GPT-4o-mini client for the keyboard extension.
// Uses pure URLSession — no third-party SDKs required.
// Loads the API key from the shared Keychain access group.

import Foundation

// MARK: - Errors

enum AIServiceError: LocalizedError {
    case noAPIKey
    case emptyMessage
    case networkError(Error)
    case invalidResponse(Int)
    case parsingFailed
    case dailyLimitReached
    case timeout

    var errorDescription: String? {
        switch self {
        case .noAPIKey:          return "No OpenAI API key found. Please add it in the CoReply app → Settings."
        case .emptyMessage:      return "Message cannot be empty."
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        case .invalidResponse(let code): return "Server returned HTTP \(code)."
        case .parsingFailed:     return "Could not parse AI response."
        case .dailyLimitReached: return "Daily reply limit reached. Upgrade to Pro for unlimited replies."
        case .timeout:           return "Request timed out. Please try again."
        }
    }
}

// MARK: - OpenAI Request / Response Models

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double
    let max_tokens: Int
    let n: Int
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
    let index: Int
}

struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
}

// MARK: - Service

final class KeyboardAIService {

    // MARK: - Constants

    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let model = "gpt-4o-mini"
    private let timeoutInterval: TimeInterval = 15

    // MARK: - URLSession

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutInterval
        config.timeoutIntervalForResource = timeoutInterval
        return URLSession(configuration: config)
    }()

    // MARK: - API Key

    private func loadAPIKey() throws -> String {
        guard let key = KeychainService.shared.getAPIKey(), !key.isEmpty else {
            throw AIServiceError.noAPIKey
        }
        return key
    }

    // MARK: - Main Entry Point

    func generateReplies(
        message: String,
        style: ReplyStyle,
        relationshipType: RelationshipType,
        personalityProfile: PersonalityProfile?,
        goal: ConversationGoal,
        userName: String
    ) async throws -> [Reply] {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw AIServiceError.emptyMessage }

        let apiKey = try loadAPIKey()
        let (systemPrompt, userPrompt) = buildPrompt(
            message: trimmed,
            style: style,
            relationship: relationshipType,
            personality: personalityProfile,
            goal: goal,
            userName: userName
        )

        let requestBody = OpenAIRequest(
            model: model,
            messages: [
                OpenAIMessage(role: "system", content: systemPrompt),
                OpenAIMessage(role: "user",   content: userPrompt)
            ],
            temperature: temperature(for: style),
            max_tokens: 600,
            n: 1
        )

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = timeoutInterval

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(requestBody)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch let urlError as URLError where urlError.code == .timedOut {
            throw AIServiceError.timeout
        } catch {
            throw AIServiceError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.parsingFailed
        }
        guard httpResponse.statusCode == 200 else {
            throw AIServiceError.invalidResponse(httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw AIServiceError.parsingFailed
        }

        return parseReplies(from: content, style: style)
    }

    // MARK: - Temperature per Style

    private func temperature(for style: ReplyStyle) -> Double {
        switch style {
        case .bestReply:           return 0.7
        case .casual:              return 0.75
        case .funny:               return 0.9
        case .flirty:              return 0.85
        case .romantic:            return 0.8
        case .genZ:                return 0.9
        case .professional:        return 0.5
        case .savage:              return 0.85
        case .malayalam:           return 0.7
        case .manglish:            return 0.75
        case .continueConversation:return 0.7
        case .rewrite:             return 0.6
        }
    }

    // MARK: - Prompt Builder

    func buildPrompt(
        message: String,
        style: ReplyStyle,
        relationship: RelationshipType,
        personality: PersonalityProfile?,
        goal: ConversationGoal,
        userName: String
    ) -> (systemPrompt: String, userPrompt: String) {

        let personalitySection: String
        if let p = personality, !p.traits.isEmpty {
            let traitList = p.traits.prefix(5).joined(separator: ", ")
            personalitySection = """
Your personality traits: \(traitList). \
Communication style: \(p.communicationStyle). \
Let these shine naturally in your replies without explicitly mentioning them.
"""
        } else {
            personalitySection = "Write in a relatable, authentic personal voice."
        }

        let goalSection: String
        switch goal {
        case .keepConversationGoing:
            goalSection = "Goal: Keep the conversation engaging and flowing naturally. End replies in a way that invites a response."
        case .expressInterest:
            goalSection = "Goal: Express genuine interest and enthusiasm. Make the person feel valued."
        case .bePlayful:
            goalSection = "Goal: Be playful, lighthearted, and fun. Keep things breezy."
        case .beSerious:
            goalSection = "Goal: Respond thoughtfully and sincerely. Avoid jokes."
        case .resolveConflict:
            goalSection = "Goal: De-escalate tension gracefully. Be empathetic but firm."
        case .expressAffection:
            goalSection = "Goal: Express genuine affection warmly without being over-the-top."
        case .beNeutral:
            goalSection = "Goal: Respond neutrally and informatively."
        }

        let styleInstruction = styleSystemPrompt(style, relationship: relationship)
        let relationshipContext = relationshipDescription(relationship)

        let systemPrompt = """
You are an expert at crafting perfect text message replies that sound completely human, natural, and never robotic or AI-generated.

CONTEXT:
- The user (\(userName.isEmpty ? "the sender" : userName)) is replying to someone they have a \(relationshipContext) relationship with.
- \(personalitySection)
- \(goalSection)

STYLE: \(styleInstruction)

RULES:
1. Generate EXACTLY 5 different reply options, numbered 1 through 5.
2. Each reply must feel distinct — vary length, tone, and wording.
3. Sound completely human, natural, conversational. NEVER robotic, formal, or AI-sounding.
4. Do NOT include any explanations, labels, or commentary — only the numbered replies.
5. Keep each reply concise (1–3 sentences max) unless the style demands otherwise.
6. Format EXACTLY like this:
1. [reply text]
2. [reply text]
3. [reply text]
4. [reply text]
5. [reply text]
"""

        let userPrompt = "Message to reply to:\n\"\(message)\""

        return (systemPrompt, userPrompt)
    }

    // MARK: - Style System Prompts

    private func styleSystemPrompt(_ style: ReplyStyle, relationship: RelationshipType) -> String {
        switch style {
        case .bestReply:
            return """
Generate the 5 most effective, well-crafted replies possible. Choose the optimal tone based on \
the relationship context (\(relationshipDescription(relationship))). Prioritize replies that feel \
genuinely thoughtful and would get the best real-world response. Mix short punchy replies with \
slightly longer ones for variety.
"""
        case .casual:
            return """
Write super casual, relaxed, everyday replies. Use informal language, contractions, maybe a \
light emoji or two. Sound like you're texting a close friend effortlessly. Keep it chill and \
low-effort in the best way. No formal words, no stiff phrasing.
"""
        case .funny:
            return """
Write genuinely funny, witty replies with clever humor, wordplay, or relatable jokes. Each \
reply should land differently — puns, callbacks, absurdist humor, self-deprecating wit. Humor \
must feel organic, not forced. Make it actually laugh-out-loud worthy, not corny. Use emojis \
sparingly only when they enhance the joke (😂 😭 💀).
"""
        case .flirty:
            return """
Write playful, flirty replies that are charming and fun — tasteful and confident, never crude \
or explicit. Use light teasing, playful compliments, and subtle wit. Leave a little mystery. \
Be cheeky but classy. Each reply should make the other person smile and want to keep flirting \
back. Use 😏 😉 occasionally.
"""
        case .romantic:
            return """
Write warm, heartfelt, genuinely romantic replies that feel sincere and not clichéd. Express \
real affection — make the person feel deeply seen and cherished. Use poetic language sparingly \
and only where it feels natural. Each reply should make the person's heart flutter. \
Avoid cheesy lines — think real depth and warmth. Use ❤️ 🥺 tastefully.
"""
        case .genZ:
            return """
Write replies in authentic 2024–2025 Gen Z texting style. Use current slang naturally: \
no cap, slay, lowkey, fr fr, it's giving, understood the assignment, ate, era, rizz, \
delulu, snatched, main character, rent free, understood the vibe, etc. Use abbreviations \
naturally (ngl, tbh, idk, omg, lol, rn). Drop emojis like 💀 ✨ 😭 🫶 🔥 🤌. \
Sound like a real 22-year-old texting — chaotic, fun, effortlessly cool. No try-hard vibes.
"""
        case .professional:
            return """
Write polished, professional replies appropriate for a \(relationshipDescription(relationship)) \
context that still requires professionalism. Use clear, measured language. Be warm but \
appropriately formal. Avoid slang, casual contractions, or emojis. Each reply should \
demonstrate emotional intelligence and effective communication. Could be used in a professional \
or semi-formal personal context.
"""
        case .savage:
            return """
Write confidently blunt, unapologetically sharp replies. Be direct, bold, and don't sugarcoat. \
Each reply should drip with confidence and a slight edge — not mean, but assertive. \
Think: witty clapback energy, unbothered queen/king vibes, no time for nonsense. \
Each reply should make the sender think twice. Use 😤 💅 🙄 strategically. \
Stay classy — don't be rude, be POWERFUL.
"""
        case .malayalam:
            return """
Write all 5 replies ENTIRELY in Malayalam language using proper Unicode Malayalam script \
(ഉദാഹരണം: ഇത് ഒരു മലയാളം സന്ദേശം ആണ്). Do NOT use Roman letters or transliteration — \
use actual Malayalam Unicode characters only (Unicode block U+0D00–U+0D7F). \
Match the natural, conversational Malayalam that Kerala people actually use in WhatsApp \
and Instagram DMs. Use Manglish-mixed style only if absolutely natural in that context.
"""
        case .manglish:
            return """
Write all 5 replies in Manglish — Malayalam spoken/written using Roman/English alphabet letters \
exactly as Kerala people type in WhatsApp. For example: "enthanu prablem?", "njan varunnu", \
"adipoli aayirunnu", "sheriyano?", "evide aanu?". Mix English words naturally as Keralites do. \
Sound like an actual Kerala person texting casually. Do NOT use Malayalam Unicode script — \
only Roman letters. This is the Manglish style.
"""
        case .continueConversation:
            return """
Write 5 replies that skillfully continue and extend the conversation thread. Each reply should \
naturally build on what was said, ask a relevant follow-up question, share a related thought, \
or redirect the conversation in an interesting direction. Avoid dead-end responses. \
Keep the momentum going naturally — make the other person eager to reply.
"""
        case .rewrite:
            return """
Rewrite and improve the original message in 5 different ways while preserving its core intent. \
Each rewrite should be a polished, improved version: clearer, more natural, better-worded, \
and more effective at achieving the sender's goal. Vary the length and approach — \
some concise, some more expressive — but all must be significantly better than the original.
"""
        }
    }

    // MARK: - Relationship Description

    private func relationshipDescription(_ type: RelationshipType) -> String {
        switch type {
        case .girlfriend:     return "girlfriend"
        case .boyfriend:      return "boyfriend"
        case .crush:          return "crush / someone they like"
        case .friend:         return "close friend"
        case .bestFriend:     return "best friend"
        case .family:         return "family member"
        case .colleague:      return "colleague / work contact"
        case .acquaintance:   return "acquaintance"
        case .stranger:       return "stranger / new contact"
        case .exPartner:      return "ex-partner"
        case .mentor:         return "mentor or authority figure"
        }
    }

    // MARK: - Response Parser

    func parseReplies(from content: String, style: ReplyStyle) -> [Reply] {
        let lines = content.components(separatedBy: "\n")
        var replies: [Reply] = []

        // Match lines starting with "1.", "2.", etc.
        let pattern = #"^\s*(\d+)[.)]\s*(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return fallbackParse(content: content, style: style)
        }

        for line in lines {
            let nsLine = line as NSString
            let range = NSRange(location: 0, length: nsLine.length)
            if let match = regex.firstMatch(in: line, options: [], range: range) {
                let textRange = match.range(at: 2)
                if textRange.location != NSNotFound {
                    let text = nsLine.substring(with: textRange)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !text.isEmpty {
                        let reply = Reply(
                            id: UUID(),
                            text: text,
                            style: style,
                            score: placeholderScore(for: text, style: style),
                            createdAt: Date()
                        )
                        replies.append(reply)
                    }
                }
            }
        }

        // If we found fewer than 2 via regex, fallback
        if replies.count < 2 {
            return fallbackParse(content: content, style: style)
        }

        return Array(replies.prefix(5))
    }

    private func fallbackParse(content: String, style: ReplyStyle) -> [Reply] {
        // Split by double-newline paragraphs
        let paragraphs = content.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return paragraphs.prefix(5).map { text in
            Reply(
                id: UUID(),
                text: text,
                style: style,
                score: placeholderScore(for: text, style: style),
                createdAt: Date()
            )
        }
    }

    // MARK: - Scoring Heuristic

    private func placeholderScore(for text: String, style: ReplyStyle) -> ReplyScore {
        // Simple heuristics for a starting score; real scoring happens in the main app.
        let wordCount = text.components(separatedBy: .whitespaces).count
        let hasEmoji = text.unicodeScalars.contains { $0.properties.isEmojiPresentation }
        let lengthScore: Double = wordCount < 5 ? 0.6 : wordCount < 15 ? 0.8 : 0.7
        let emojiBonus: Double = hasEmoji ? 0.05 : 0.0
        let overall = min(1.0, lengthScore + emojiBonus)

        return ReplyScore(
            overall: overall,
            naturalness: overall,
            relevance: 0.85,
            engagement: overall * 0.9
        )
    }
}
