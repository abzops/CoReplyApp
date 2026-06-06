// DesignConstants.swift
// CoReply
//
// Application-wide styling variables, spacing tokens, and color themes shared across targets.

import SwiftUI

public enum DesignConstants {
    // MARK: - Colors
    
    public enum Colors {
        // Deep purple/black gradient background
        public static let backgroundStart = Color(hex: "0D0D1A")
        public static let backgroundEnd = Color(hex: "1A0D2E")
        
        // Brand Accent colors
        public static let primaryAccent = Color(hex: "8B5CF6") // Violet
        public static let secondaryAccent = Color(hex: "EC4899") // Pink
        public static let premiumGold = Color(hex: "FBBF24") // Gold
        
        // System / Status colors
        public static let success = Color(hex: "10B981")
        public static let warning = Color(hex: "F59E0B")
        public static let danger = Color(hex: "EF4444")
        
        // Neutrals
        public static let cardBg = Color.white.opacity(0.08)
        public static let cardBorder = Color.white.opacity(0.12)
        public static let textPrimary = Color.white
        public static let textSecondary = Color.white.opacity(0.7)
        public static let textMuted = Color.white.opacity(0.4)
    }
    
    // MARK: - Gradients
    
    public enum Gradients {
        public static let primaryBackground = LinearGradient(
            colors: [Colors.backgroundStart, Colors.backgroundEnd],
            startPoint: .top,
            endPoint: .bottom
        )
        
        public static let buttonGradient = LinearGradient(
            colors: [Colors.primaryAccent, Colors.secondaryAccent],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        public static let premiumGradient = LinearGradient(
            colors: [Color(hex: "F59E0B"), Color(hex: "EF4444")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Sizing & Padding
    
    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
    }
    
    // MARK: - Corner Radii
    
    public enum Radius {
        public static let small: CGFloat = 8
        public static let medium: CGFloat = 16
        public static let large: CGFloat = 24
    }
}
