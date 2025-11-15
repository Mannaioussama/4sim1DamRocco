//
//  AuthStore.swift
//  NEXO
//
//  Created by ROCCO 4X on 7/11/2025.
//

import Foundation
import Combine

@MainActor
final class AuthStore: ObservableObject {
    // MARK: - Shared Instance
    static let shared = AuthStore()
    
    @Published private(set) var isLoggedIn: Bool = false
    @Published private(set) var currentUser: User? = nil

    private let tokenStore: TokenStoring

    // MARK: - Initializers

    // Designated initializer for testing or custom token store
    init(tokenStore: TokenStoring) {
        self.tokenStore = tokenStore
        // Try restoring previous session
        if let token = try? tokenStore.load(), !token.isEmpty {
            // Mirror into AuthTokenManager so services that read from it can work
            AuthTokenManager.shared.saveToken(token)
            self.isLoggedIn = true
        }
    }

    // Public convenience initializer for default Keychain-backed store
    convenience init() {
        self.init(tokenStore: KeychainTokenStore.shared)
    }

    // MARK: - API Calls

    func login(email: String, password: String) async throws {
        let resp = try await AuthAPI.login(.init(email: email, password: password))
        try tokenStore.save(token: resp.accessToken)
        // Mirror token so ActivityAPIService can read it
        AuthTokenManager.shared.saveToken(resp.accessToken)
        currentUser = resp.user
        isLoggedIn = true
    }

    func register(email: String, password: String, name: String, location: String) async throws {
        let resp = try await AuthAPI.register(.init(email: email, password: password, name: name, location: location))

        if resp.accessToken.isEmpty {
            // Backend didn’t return a token on register — auto-login with the same credentials.
            try await login(email: email, password: password)
            return
        }

        try tokenStore.save(token: resp.accessToken)
        // Mirror token so ActivityAPIService can read it
        AuthTokenManager.shared.saveToken(resp.accessToken)
        currentUser = resp.user
        isLoggedIn = true
    }

    func forgotPassword(email: String) async throws {
        _ = try await AuthAPI.forgotPassword(.init(email: email))
    }

    func validateResetToken(_ token: String) async throws -> Bool {
        let resp = try await AuthAPI.validateResetToken(token)
        return resp.valid
    }

    func resetPassword(token: String, newPassword: String) async throws {
        _ = try await AuthAPI.resetPassword(.init(token: token, password: newPassword))
    }

    func logout() {
        try? tokenStore.remove()
        currentUser = nil
        isLoggedIn = false
        // Keep both stores in sync
        AuthTokenManager.shared.clearToken()
    }

    func accessToken() -> String? {
        try? tokenStore.load()
    }
}
