//
//  KeychainTokenStore.swift
//  NEXO
//
//  Created by ROCCO 4X on 7/11/2025.
//

import Foundation
import Security

protocol TokenStoring {
    func save(token: String) throws
    func load() throws -> String?
    func remove() throws
}

final class KeychainTokenStore: TokenStoring {
    // MARK: - Shared Instance
    static let shared = KeychainTokenStore()
    
    private let service = "com.nexo.auth"
    private let account = "accessToken"
    
    // Private init for singleton
    private init() {}
    
    // MARK: - TokenStoring Protocol
    
    func save(token: String) throws {
        let data = Data(token.utf8)
        try remove() // ensure a single copy
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
    }
    
    func load() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
        return String(data: data, encoding: .utf8)
    }
    
    func remove() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
    }
    
    // MARK: - Helper Methods
    
    /// Convenience method to get access token (returns nil if not found or error)
    func getAccessToken() -> String? {
        return try? load()
    }
    
    /// Check if a token exists
    func hasToken() -> Bool {
        return (try? load()) != nil
    }
}
