// Logger.swift
// CoReply
//
// Structured system logs manager using Apple's os.Logger API.

import Foundation
import os

public final class AppLogger {
    private static let subsystem = AppConstants.bundleID
    
    public static let ai = Logger(subsystem: subsystem, category: "ai")
    public static let keyboard = Logger(subsystem: subsystem, category: "keyboard")
    public static let supabase = Logger(subsystem: subsystem, category: "supabase")
    public static let store = Logger(subsystem: subsystem, category: "store")
    public static let system = Logger(subsystem: subsystem, category: "system")
    
    public static func debug(_ message: String, category: Logger = system) {
        #if DEBUG
        category.debug("\(message, privacy: .public)")
        #endif
    }
    
    public static func info(_ message: String, category: Logger = system) {
        category.info("\(message, privacy: .public)")
    }
    
    public static func warning(_ message: String, category: Logger = system) {
        category.warning("\(message, privacy: .public)")
    }
    
    public static func error(_ message: String, error: Error? = nil, category: Logger = system) {
        if let error = error {
            category.error("\(message, privacy: .public) - Error: \(error.localizedDescription, privacy: .public)")
        } else {
            category.error("\(message, privacy: .public)")
        }
    }
}
