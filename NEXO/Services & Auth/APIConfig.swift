//
//  APIConfig.swift
//  NEXO
//
//  Created by ROCCO 4X on 7/11/2025.
//

import Foundation

enum APIConfig {
    // Railway base URL (no trailing slash)
    static let baseURL = URL(string: "https://apinest-production.up.railway.app")!

    static func endpoint(_ path: String) -> URL {
        if path.hasPrefix("/") {
            return baseURL.appendingPathComponent(String(path.dropFirst()))
        } else {
            return baseURL.appendingPathComponent(path)
        }
    }
}
