//
//  APIConfiguration.swift
//  NEXO
//
//  Created by ROCCO 4X on 13/11/2025.
//

import Foundation

struct APIConfiguration {
    // MARK: - Gemini AI Configuration
    
    /// Your Gemini API Key
    /// Get your API key from: https://makersuite.google.com/app/apikey
    /// 
    /// IMPORTANT: For production apps, store this securely using:
    /// - Keychain Services
    /// - Environment variables
    /// - Secure configuration files
    /// 
    /// Never commit API keys to version control!
    static let geminiAPIKey: String = {
        // Try to load from environment first (recommended for development)
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        // Try to load from a local config file (not tracked in git)
        if let path = Bundle.main.path(forResource: "APIKeys", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let key = plist["GeminiAPIKey"] as? String, !key.isEmpty {
            return key
        }
        
        // Fallback: Use your actual API key
        return "AIzaSyDQoeMR2Fvjf27iZs2YNM90IwQEmg-_8lo"
    }()
    
    // MARK: - API Endpoints
    static let geminiBaseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
    
    // MARK: - Configuration Validation
    static var isGeminiConfigured: Bool {
        return !geminiAPIKey.isEmpty && geminiAPIKey != "YOUR_GEMINI_API_KEY_HERE"
    }
    
    static func validateConfiguration() -> ConfigurationStatus {
        if !isGeminiConfigured {
            return .missingGeminiKey
        }
        return .valid
    }
}

enum ConfigurationStatus {
    case valid
    case missingGeminiKey
    
    var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .missingGeminiKey:
            return "Gemini API key is not configured. Please add your API key to APIConfiguration.swift"
        }
    }
}
