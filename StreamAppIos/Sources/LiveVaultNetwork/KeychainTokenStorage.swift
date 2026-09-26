import Foundation
import Security
import LiveVaultCommon

public protocol TokenStorageProtocol: Sendable {
    func saveTokens(accessToken: String, refreshToken: String) throws
    func getAccessToken() -> String?
    func getRefreshToken() -> String?
    func saveUserProfile(_ user: UserProfile) throws
    func getUserProfile() -> UserProfile?
    func clearAll()
}

public final class KeychainTokenStorage: TokenStorageProtocol, @unchecked Sendable {
    public static let shared = KeychainTokenStorage()
    
    private let service: String
    private let accessGroup: String?
    private let lock = NSLock()
    
    private enum Key {
        static let accessToken = "livevault_access_token"
        static let refreshToken = "livevault_refresh_token"
        static let userProfile = "livevault_user_profile"
    }
    
    public init(service: String = LiveVaultConstants.keychainService, accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }
    
    public func saveTokens(accessToken: String, refreshToken: String) throws {
        lock.lock()
        defer { lock.unlock() }
        
        try setString(accessToken, forKey: Key.accessToken)
        try setString(refreshToken, forKey: Key.refreshToken)
    }
    
    public func getAccessToken() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return getString(forKey: Key.accessToken)
    }
    
    public func getRefreshToken() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return getString(forKey: Key.refreshToken)
    }
    
    public func saveUserProfile(_ user: UserProfile) throws {
        lock.lock()
        defer { lock.unlock() }
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(user)
        try setData(data, forKey: Key.userProfile)
    }
    
    public func getUserProfile() -> UserProfile? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let data = getData(forKey: Key.userProfile) else { return nil }
        return try? JSONDecoder().decode(UserProfile.self, from: data)
    }
    
    public func clearAll() {
        lock.lock()
        defer { lock.unlock() }
        
        delete(forKey: Key.accessToken)
        delete(forKey: Key.refreshToken)
        delete(forKey: Key.userProfile)
    }
    
    // MARK: - Keychain Helpers
    private func setString(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else { return }
        try setData(data, forKey: key)
    }
    
    private func getString(forKey key: String) -> String? {
        guard let data = getData(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private func setData(_ data: Data, forKey key: String) throws {
        delete(forKey: key)
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AppError.keychainError("Failed to save data to Keychain. OSStatus: \(status)")
        }
    }
    
    private func getData(forKey key: String) -> Data? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess, let data = dataTypeRef as? Data else {
            return nil
        }
        return data
    }
    
    private func delete(forKey key: String) {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        SecItemDelete(query as CFDictionary)
    }
}
