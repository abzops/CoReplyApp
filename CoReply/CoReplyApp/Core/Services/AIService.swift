// AIService.swift
// CoReply
//
// OpenAI GPT-4o-mini request manager for main app.

import Foundation

public protocol AIServiceProtocol: Sendable {
    func generateReplies(
        message: String,
        relationshipType: RelationshipType,
        style: ReplyStyle,
        personality: PersonalityProfile?,
        goal: ConversationGoal,
        userName: String
    ) async throws -> [Reply]
}

public final class AIService: AIServiceProtocol {
    public static let shared = AIService()
    
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let model = AppConstants.AI.openAIModel
    private let timeoutInterval: TimeInterval = 15
    
    private init() {}
    
    private func loadAPIKey() throws -> String {
        guard let key = KeychainService.shared.getAPIKey(), !key.isEmpty else {
            throw AIServiceError.noAPIKey
        }
        return key
    }
    
    public func generateReplies(
        message: String,
        relationshipType: RelationshipType,
        style: ReplyStyle,
        personality: PersonalityProfile?,
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
            personality: personality,
            goal: goal,
            userName: userName
        )
        
        let requestBody = OpenAIRequest(
            model: model,
            messages: [
                OpenAIMessage(role: "system", content: systemPrompt),
                OpenAIMessage(role: "user", content: userPrompt)
            ],
            temperature: temperature(for: style),
            max_tokens: AppConstants.AI.maxTokens,
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
            (data, response) = try await URLSession.shared.data(for: urlRequest)
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
    
    // MARK: - Prompt & Style Configurations
    
    private func temperature(for style: ReplyStyle) -> Double {
        switch style {
        case .bestReply: return 0.7
        case .casual: return 0.8
        case .funny: return 0.9
        case .flirty: return 0.85
        case .romantic: return 0.75
        case .genZ: return 0.9
        case .professional: return 0.4
        case .savage: return 0.85
        case .malayalam: return 0.7
        case .manglish: return 0.75
        case .continueConversation: return 0.7
        case .rewrite: return 0.6
        }
    }
    
    private func buildPrompt(
        message: String,
        style: ReplyStyle,
        relationship: RelationshipType,
        personality: PersonalityProfile?,
        goal: ConversationGoal,
        userName: String
    ) -> (systemPrompt: String, userPrompt: String) {
        
        let personalitySection: String
        if let p = personality, !p.traits.isEmpty {
            let traitsString = p.traits.prefix(5).joined(separator: ", ")
            personalitySection = "Write in the voice of a personality with traits: \(traitsString) and communication style described as: \(p.communicationStyle)."
        } else {
            personalitySection = "Write in a relatable, authentic human voice."
        }
        
        let goalSection: String
        switch goal {
        case .keepConversationGoing:
            goalSection = "Goal: Keep the chat going naturally, encouraging a reply."
        case .expressInterest:
            goalSection = "Goal: Show genuine interest and engagement."
        case .bePlayful:
            goalSection = "Goal: Inject playfulness and light teasing."
        case .beSerious:
            goalSection = "Goal: Keep the tone sincere and empathetic."
        case .resolveConflict:
            goalSection = "Goal: De-escalate tension and respond calmly."
        case .expressAffection:
            goalSection = "Goal: Express deep care and affection warmly."
        case .beNeutral:
            goalSection = "Goal: Keep it straightforward and balanced."
        }
        
        let styleInstruction = styleSystemPrompt(style)
        let nameContext = userName.isEmpty ? "the user" : userName
        
        let systemPrompt = """
        You are a highly skilled communication assistant. Your task is to write perfect reply suggestions that look exactly like a real human sent them.
        
        CONTEXT:
        - Replying to a: \(relationship.displayName) (\(relationship.emoji))
        - User's identity: \(nameContext)
        - \(personalitySection)
        - \(goalSection)
        
        STYLE:
        \(styleInstruction)
        
        RULES:
        1. Output EXACTLY 5 different options, numbered 1 to 5.
        2. Vary length, style, and structure between options.
        3. Never sound like an AI. Do not use repetitive words, overly polite greetings, or formal phrasing.
        4. No explanation or preambles. Only output the numbered list.
        5. Format exactly:
        1. [Option 1]
        2. [Option 2]
        3. [Option 3]
        4. [Option 4]
        5. [Option 5]
        """
        
        let userPrompt = "Write replies for this message:\n\"\(message)\""
        return (systemPrompt, userPrompt)
    }
    
    private func styleSystemPrompt(_ style: ReplyStyle) -> String {
        switch style {
        case .bestReply:
            return "Provide balanced, smart, highly engaging replies tailored specifically to the relationship."
        case .casual:
            return "Casual, friendly, everyday texting style. Lowercase, short, minimal punctuation."
        case .funny:
            return "Clever, witty, actually funny responses. Playful, dry humor, or situational jokes."
        case .flirty:
            return "Playful, charming, teasing. Confidence with taste. Not overly sexual or blunt."
        case .romantic:
            return "Sweet, warm, sincere, and affectionate. Emotional resonance without cheesiness."
        case .genZ:
            return "Chaos energy, Gen Z internet slang (no cap, lowkey, fr, 💀, 😭, slay, rizz). No capitals, minimal punctuation."
        case .professional:
            return "Polite, well-structured, clear, professional. No emoji."
        case .savage:
            return "Confident clapbacks, sassy, unapologetic but classy. Strong boundaries, unbothered."
        case .malayalam:
            return "Create 5 replies completely in Malayalam script (ഉദാഹരണം: സുഖമാണോ?). Conversational WhatsApp style."
        case .manglish:
            return "Create 5 replies in Manglish (Malayalam written in English script, e.g., 'entha ee parayunnath?', 'parayam dhaa')."
        case .continueConversation:
            return "Generate replies that ask questions or share thoughts to carry the thread forward."
        case .rewrite:
            return "Preserve intent, but rewrite the user's thought to sound much better, more confident, and smooth."
        }
    }
    
    private func parseReplies(from content: String, style: ReplyStyle) -> [Reply] {
        let lines = content.components(separatedBy: "\n")
        var replies: [Reply] = []
        
        let pattern = #"^\s*(\d+)[.)]\s*(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return fallbackParse(content, style: style)
        }
        
        for line in lines {
            let ns = line as NSString
            let range = NSRange(location: 0, length: ns.length)
            if let match = regex.firstMatch(in: line, options: [], range: range) {
                let textRange = match.range(at: 2)
                if textRange.location != NSNotFound {
                    let text = ns.substring(with: textRange).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !text.isEmpty {
                        replies.append(Reply(
                            text: text,
                            style: style,
                            score: evaluateHeuristics(text: text)
                        ))
                    }
                }
            }
        }
        
        if replies.count < 3 {
            return fallbackParse(content, style: style)
        }
        
        return Array(replies.prefix(5))
    }
    
    private func fallbackParse(_ content: String, style: ReplyStyle) -> [Reply] {
        let paragraphs = content.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.hasPrefix("1.") && !$0.hasPrefix("2.") }
        
        return paragraphs.prefix(5).map { text in
            Reply(
                text: text,
                style: style,
                score: evaluateHeuristics(text: text)
            )
        }
    }
    
    private func evaluateHeuristics(text: String) -> ReplyScore {
        let wordCount = text.components(separatedBy: .whitespaces).count
        let naturalness = wordCount > 2 && wordCount < 18 ? 0.92 : 0.78
        let relevance = 0.88
        let engagement = text.contains("?") ? 0.90 : 0.80
        
        let overall = (naturalness + relevance + engagement) / 3.0
        return ReplyScore(
            overall: overall,
            naturalness: naturalness,
            relevance: relevance,
            engagement: engagement
        )
    }
}
