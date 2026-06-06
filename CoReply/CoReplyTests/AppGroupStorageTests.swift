// AppGroupStorageTests.swift
// CoReplyTests
//
// Unit tests checking AppGroup storage state sync and limit evaluations.

import XCTest
@testable import CoReplyApp

final class AppGroupStorageTests: XCTestCase {
    
    private var storage: AppGroupStorage!
    
    @MainActor
    override func setUpWithError() throws {
        super.setUp()
        storage = AppGroupStorage.shared
        storage.clearAll()
    }
    
    @MainActor
    override func tearDownWithError() throws {
        storage.clearAll()
        storage = nil
        super.tearDown()
    }
    
    @MainActor
    func testDailyReplyCountIncrements() {
        XCTAssertEqual(storage.dailyReplyCount, 0)
        
        storage.incrementDailyReplyCount()
        XCTAssertEqual(storage.dailyReplyCount, 1)
        
        storage.incrementDailyReplyCount()
        XCTAssertEqual(storage.dailyReplyCount, 2)
    }
    
    @MainActor
    func testFreeTierGenerationLimits() {
        storage.subscriptionTier = .free
        storage.dailyReplyCount = 18
        
        XCTAssertTrue(storage.canGenerateReply())
        XCTAssertEqual(storage.remainingReplies(), 2)
        
        storage.incrementDailyReplyCount() // 19
        storage.incrementDailyReplyCount() // 20
        
        XCTAssertFalse(storage.canGenerateReply())
        XCTAssertEqual(storage.remainingReplies(), 0)
    }
    
    @MainActor
    func testProTierHasInfiniteReplies() {
        storage.subscriptionTier = .pro
        storage.dailyReplyCount = 100
        
        XCTAssertTrue(storage.canGenerateReply())
        XCTAssertEqual(storage.remainingReplies(), Int.max)
    }
}
