// AIServiceTests.swift
// CoReplyTests
//
// Unit tests verifying AI prompt formatting and response list parsing rules.

import XCTest
@testable import CoReplyApp

final class AIServiceTests: XCTestCase {
    
    private var aiService: AIService!
    
    override func setUpWithError() throws {
        super.setUp()
        aiService = AIService.shared
    }
    
    override func tearDownWithError() throws {
        aiService = nil
        super.tearDown()
    }
    
    func testPromptParsingWithProperNumberedList() {
        let content = """
        1. Sure, that sounds fun!
        2. Let me think about it.
        3. No problem at all.
        4. I'll let you know soon.
        5. Let's do it tomorrow!
        """
        
        let replies = aiService.parseReplies(from: content, style: .casual)
        
        XCTAssertEqual(replies.count, 5)
        XCTAssertEqual(replies[0].text, "Sure, that sounds fun!")
        XCTAssertEqual(replies[0].style, .casual)
        XCTAssertEqual(replies[4].text, "Let's do it tomorrow!")
    }
    
    func testPromptParsingWithFallbackDoubleNewline() {
        let content = """
        How about we meet up at 5?
        
        Let's go for coffee instead.
        
        Sounds perfect to me!
        """
        
        let replies = aiService.parseReplies(from: content, style: .casual)
        
        XCTAssertEqual(replies.count, 3)
        XCTAssertEqual(replies[0].text, "How about we meet up at 5?")
        XCTAssertEqual(replies[2].text, "Sounds perfect to me!")
    }
    
    func testHeuristicsEvaluation() {
        let content = "Sure, I will be there."
        // Accessing the private parser is not possible directly, but we can verify overall response builder outputs
        let replies = aiService.parseReplies(from: "1. \(content)", style: .casual)
        
        XCTAssertFalse(replies.isEmpty)
        XCTAssertTrue(replies[0].score.overall > 0.5)
        XCTAssertTrue(replies[0].score.naturalness > 0.5)
    }
}
