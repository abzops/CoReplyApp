// ClipboardServiceTests.swift
// CoReplyTests
//
// Unit tests verifying clipboard text normalization behaviors.

import XCTest
import UIKit
@testable import CoReplyApp

final class ClipboardServiceTests: XCTestCase {
    
    @MainActor
    func testTextNormalizationTrimsSpacesAndNewlines() {
        let input = "   Hey there!   \n\n\nHow is it going?   \n"
        let service = ClipboardService.shared
        
        let result = service.normalizeText(input)
        
        XCTAssertEqual(result, "Hey there!\n\nHow is it going?")
    }
    
    @MainActor
    func testTextNormalizationCollapsesMultipleSpaces() {
        let input = "This   is   a   sentence    with   many    spaces."
        let service = ClipboardService.shared
        
        let result = service.normalizeText(input)
        
        XCTAssertEqual(result, "This is a sentence with many spaces.")
    }
}
