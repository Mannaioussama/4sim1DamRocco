//
//  ProfileImageService.swift
//  NEXO
//
//  Created by ChatGPT on 11/7/2025.
//

import UIKit

enum ProfileImageError: Error {
    case processingFailed
}

protocol ProfileImageUploader {
    func uploadProfileImage(data: Data, fileName: String, mimeType: String) async throws -> URL
}

final class ProfileImageService {
    // Downscale to reduce size and compress
    func processForUpload(_ image: UIImage, maxDimension: CGFloat = 640, quality: CGFloat = 0.85) throws -> Data {
        let size = image.size
        let scale = min(1, maxDimension / max(size.width, size.height))
        let target = CGSize(width: size.width * scale, height: size.height * scale)

        UIGraphicsBeginImageContextWithOptions(target, true, 1.0)
        image.draw(in: CGRect(origin: .zero, size: target))
        let scaled = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let scaled, let data = scaled.jpegData(compressionQuality: quality) else {
            throw ProfileImageError.processingFailed
        }
        return data
    }
}

// Stub uploader — replace with your NestJS call later.
final class StubProfileImageUploader: ProfileImageUploader {
    func uploadProfileImage(data: Data, fileName: String, mimeType: String) async throws -> URL {
        try await Task.sleep(nanoseconds: 400_000_000)
        return URL(string: "https://cdn.example.com/avatars/\(UUID().uuidString).jpg")!
    }
}

