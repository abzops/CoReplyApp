// AppGroupStorage.swift
// CoReply
//
// Persistent storage engine using shared App Group UserDefaults.

import Foundation

@MainActor
public final class AppGroupStorage: ObservableObject {
    public static let shared = AppGroupStorage()
    
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {
        guard let defaults = UserDefaults(suiteName: AppConstants.appGroupID) else {
            fatalError("Failed to initialize UserDefaults with suite name: \(AppConstants.appGroupID). Ensure your provisioning profile supports App Groups.")
        }
        self.defaults = defaults
    }
    
    // MARK: - Generic Get/Set Methods used by Onboarding/Settings
    
    public func set(value: String, forKey key: String) {
        defaults.set(value, forKey: key)
    }
    
    public func string(forKey key: String) -> String? {
        return defaults.string(forKey: key)
    }
    
    public func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
    
    // MARK: - User Persistence
    
    public func saveUser(_ user: CoUser) {
        if let encoded = try? encoder.encode(user) {
            defaults.set(encoded, forKey: "co_user")
            self.userID = user.id.uuidString
            self.userName = user.name
            self.userLanguage = user.language.rawValue
            self.subscriptionTier = user.subscriptionTier
        }
    }
    
    public func loadUser() -> CoUser? {
        guard let data = defaults.data(forKey: "co_user") else { return nil }
        return try? decoder.decode(CoUser.self, from: data)
    }
    
    // MARK: - Properties
    
    public var lastClipboardText: String? {
        get { defaults.string(forKey: AppConstants.AppGroup.lastClipboardText) }
        set {
            defaults.set(newValue, forKey: AppConstants.AppGroup.lastClipboardText)
            objectWillChange.send()
        }
    }
    
    public var lastClipboardChangeCount: Int {
        get { defaults.integer(forKey: AppConstants.AppGroup.lastClipboardChangeCount) }
        set {
            defaults.set(newValue, forKey: AppConstants.AppGroup.lastClipboardChangeCount)
            objectWillChange.send()
        }
    }
    
    public var activeProfileID: UUID? {
        get {
            guard let str = defaults.string(forKey: AppConstants.AppGroup.activeProfileID) else { return nil }
            return UUID(uuidString: str)
        }
        set {
            defaults.set(newValue?.uuidString, forKey: AppConstants.AppGroup.activeProfileID)
            objectWillChange.send()
        }
    }
    
    public var activePersonalityID: String? {
        get { defaults.string(forKey: AppConstants.AppGroup.activePersonalityID) }
        set {
            defaults.set(newValue, forKey: AppConstants.AppGroup.activePersonalityID)
            objectWillChange.send()
        }
    }
    
    public var cachedReplies: CachedReplySet? {
        get {
            guard let data = defaults.data(forKey: AppConstants.AppGroup.cachedReplies) else { return nil }
            return try? decoder.decode(CachedReplySet.self, from: data)
        }
        set {
            if let value = newValue, let data = try? encoder.encode(value) {
                defaults.set(data, forKey: AppConstants.AppGroup.cachedReplies)
            } else {
                defaults.removeObject(forKey: AppConstants.AppGroup.cachedReplies)
            }
            objectWillChange.send()
        }
    }
    
    public var dailyReplyCount: Int {
        get {
            resetDailyCountIfNeeded()
            return defaults.integer(forKey: AppConstants.AppGroup.dailyReplyCount)
        }
        set {
            defaults.set(newValue, forKey: AppConstants.AppGroup.dailyReplyCount)
            objectWillChange.send()
        }
    }
    
    private func resetDailyCountIfNeeded() {
        let resetDate = defaults.object(forKey: AppConstants.AppGroup.dailyResetDate) as? Date ?? Date.distantPast
        if !Calendar.current.isDateInToday(resetDate) {
            defaults.set(0, forKey: AppConstants.AppGroup.dailyReplyCount)
            defaults.set(Date(), forKey: AppConstants.AppGroup.dailyResetDate)
            objectWillChange.send()
        }
    }
    
    public func incrementDailyReplyCount() {
        dailyReplyCount = dailyReplyCount + 1
    }
    
    public var userID: String? {
        get { defaults.string(forKey: AppConstants.AppGroup.userID) }
        set { defaults.set(newValue, forKey: AppConstants.AppGroup.userID) }
    }
    
    public var userName: String? {
        get { defaults.string(forKey: AppConstants.AppGroup.userName) }
        set { defaults.set(newValue, forKey: AppConstants.AppGroup.userName) }
    }
    
    public var userLanguage: String {
        get { defaults.string(forKey: AppConstants.AppGroup.userLanguage) ?? "English" }
        set { defaults.set(newValue, forKey: AppConstants.AppGroup.userLanguage) }
    }
    
    public var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: AppConstants.AppGroup.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: AppConstants.AppGroup.hasCompletedOnboarding) }
    }
    
    public var subscriptionTier: SubscriptionTier {
        get {
            guard let raw = defaults.string(forKey: AppConstants.AppGroup.subscriptionTier),
                  let tier = SubscriptionTier(rawValue: raw) else { return .free }
            return tier
        }
        set {
            defaults.set(newValue.rawValue, forKey: AppConstants.AppGroup.subscriptionTier)
            objectWillChange.send()
        }
    }
    
    public var isOpenAIKeyStored: Bool {
        get { defaults.bool(forKey: AppConstants.AppGroup.isOpenAIKeyStored) }
        set {
            defaults.set(newValue, forKey: AppConstants.AppGroup.isOpenAIKeyStored)
            objectWillChange.send()
        }
    }
    
    public func canGenerateReply() -> Bool {
        if subscriptionTier != .free { return true }
        return dailyReplyCount < AppConstants.Subscription.freeReplyLimit
    }
    
    public func remainingReplies() -> Int {
        if subscriptionTier != .free { return Int.max }
        return max(0, AppConstants.Subscription.freeReplyLimit - dailyReplyCount)
    }
    
    public func clearAll() {
        defaults.removeObject(forKey: "co_user")
        defaults.removeObject(forKey: AppConstants.AppGroup.lastClipboardText)
        defaults.removeObject(forKey: AppConstants.AppGroup.lastClipboardChangeCount)
        defaults.removeObject(forKey: AppConstants.AppGroup.activeProfileID)
        defaults.removeObject(forKey: AppConstants.AppGroup.activePersonalityID)
        defaults.removeObject(forKey: AppConstants.AppGroup.cachedReplies)
        defaults.removeObject(forKey: AppConstants.AppGroup.dailyReplyCount)
        defaults.removeObject(forKey: AppConstants.AppGroup.dailyResetDate)
        defaults.removeObject(forKey: AppConstants.AppGroup.userID)
        defaults.removeObject(forKey: AppConstants.AppGroup.userName)
        defaults.removeObject(forKey: AppConstants.AppGroup.userLanguage)
        defaults.removeObject(forKey: AppConstants.AppGroup.hasCompletedOnboarding)
        defaults.removeObject(forKey: AppConstants.AppGroup.subscriptionTier)
        defaults.removeObject(forKey: AppConstants.AppGroup.isOpenAIKeyStored)
        defaults.removeObject(forKey: AppConstants.AppGroup.defaultLanguage)
        defaults.removeObject(forKey: AppConstants.AppGroup.defaultCommunicationStyle)
        objectWillChange.send()
    }
}
