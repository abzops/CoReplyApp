// SharedConstants.swift
// CoReply
//
// Configuration constants shared across Main App and Keyboard Extension.

import Foundation

public enum AppConstants {
    public static let appGroupID = "group.com.abhinand.coreply"
    public static let keychainAccessGroup = "com.abhinand.coreply"
    public static let bundleID = "com.abhinand.coreply"
    public static let keyboardBundleID = "com.abhinand.coreply.keyboard"
    
    public enum AI {
        public static let openAIBaseURL = "https://api.openai.com/v1"
        public static let openAIModel = "gpt-4o-mini"
        public static let maxReplies = 5
        public static let maxTokens = 600
        public static let temperature = 0.8
    }
    
    public enum Keys {
        public static let openAIKey = "openai_api_key"
        public static let supabaseURL = "supabase_url"
        public static let supabaseAnonKey = "supabase_anon_key"
        public static let revenueCatKey = "revenuecat_api_key"
    }
    
    public enum AppGroup {
        public static let lastClipboardText = "last_clipboard_text"
        public static let lastClipboardChangeCount = "last_clipboard_change_count"
        public static let activeProfileID = "active_profile_id"
        public static let activePersonalityID = "active_personality_id"
        public static let cachedReplies = "cached_replies"
        public static let dailyReplyCount = "daily_reply_count"
        public static let dailyResetDate = "daily_reply_reset_date"
        public static let userID = "user_id"
        public static let hasCompletedOnboarding = "has_completed_onboarding"
        public static let subscriptionTier = "subscription_tier"
        public static let isOpenAIKeyStored = "openai_key_stored"
        
        public static let userName = "user_name"
        public static let userLanguage = "user_language"
        
        // Settings / Config defaults
        public static let defaultLanguage = "default_language"
        public static let defaultCommunicationStyle = "default_communication_style"
    }
    
    public enum Subscription {
        public static let freeReplyLimit = 20
        public static let proProductID = "com.abhinand.coreply.pro_monthly"
        public static let premiumProductID = "com.abhinand.coreply.premium_monthly"
        public static let proAnnualProductID = "com.abhinand.coreply.pro_annual"
    }
    
    public enum Supabase {
        public static let defaultURL = "https://your-project.supabase.co"
    }
}
