// KeychainService.swift
// CoReply
//
// Thread-safe Keychain service for secure credentials sharing.

import Foundation
import Security

public final class KeychainService: @unchecked Sendable {
    public static let shared = KeychainService()
    
    private let lock = NSLock()
    private let accessGroup = AppConstants.keychainAccessGroup
    
    private init() {}
    
    // MARK: - API Key Helper
    
    public func getAPIKey() -> String? {
        return load(key: AppConstants.Keys.openAIKey)
    }
    
    // MARK: - Save
    
    @discardableResult
    public func save(key: String, value: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        guard let data = value.data(using: .utf8) else { return false }
        
        // Delete first to avoid duplicate item errors
        deleteWithoutLock(key: key)
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        #if !targetEnvironment(simulator)
        query[kSecAttrAccessGroup as String] = accessGroup
        #endif
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Load
    
    public func load(key: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        #if !targetEnvironment(simulator)
        query[kSecAttrAccessGroup as String] = accessGroup
        #endif
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess, let data = dataTypeRef as? Data else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - Delete
    
    @discardableResult
    public func delete(key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return deleteWithoutLock(key: key)
    }
    
    @discardableResult
    private func deleteWithoutLock(key: String) -> Bool {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        #if !targetEnvironment(simulator)
        query[kSecAttrAccessGroup as String] = accessGroup
        #endif
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    public func clearAll() {
        lock.lock()
        defer { lock.unlock() }
        
        let keys = [
            AppConstants.Keys.openAIKey,
            AppConstants.Keys.supabaseURL,
            AppConstants.Keys.supabaseAnonKey,
            AppConstants.Keys.revenueCatKey
        ]
        
        for key in keys {
            deleteWithoutLock(key: key)
        }
    }
}
