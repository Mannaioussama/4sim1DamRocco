//
//  AuthTokenManager.swift
//  NEXO
//
//  Created by ROCCO 4X on 13/11/2025.
//

import Foundation

class AuthTokenManager {
    static let shared = AuthTokenManager()
    
    private let tokenKey = "auth_token"
    private let userIdKey = "user_id"
    
    private init() {}
    
    // MARK: - Token Management
    
    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        print("🔐 Auth token saved")
    }
    
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    func clearToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
        print("🔐 Auth token cleared")
    }
    
    func isAuthenticated() -> Bool {
        return getToken() != nil
    }
    
    // MARK: - User ID Management
    
    func saveUserId(_ userId: String) {
        UserDefaults.standard.set(userId, forKey: userIdKey)
    }
    
    func getUserId() -> String? {
        return UserDefaults.standard.string(forKey: userIdKey)
    }
    
    // MARK: - Authentication Status
    
    func requiresAuthentication() -> Bool {
        return !isAuthenticated()
    }
    
    func getCurrentUserInfo() -> (token: String?, userId: String?) {
        return (getToken(), getUserId())
    }
}
