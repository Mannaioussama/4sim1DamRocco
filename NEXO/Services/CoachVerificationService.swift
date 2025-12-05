import Foundation

struct CoachVerificationRequest: Codable {
    let userType: String
    let fullName: String
    let email: String
    let about: String
    let specialization: String
    let yearsOfExperience: String
    let certifications: String
    let location: String
    let documents: [String]
    let note: String?
}

struct DocumentAnalysisResult: Codable {
    let documentsVerified: Int
    let totalDocuments: Int
    let documentTypes: [String]
    let isValid: Bool
}

struct CoachVerificationResponse: Codable {
    let isCoach: Bool
    let confidenceScore: Double
    let verificationReasons: [String]
    let aiAnalysis: String?
    let documentAnalysis: DocumentAnalysisResult?
}

final class CoachVerificationService {
    static let shared = CoachVerificationService()
    private init() {}
    
    private let session = URLSession.shared
    
    func verifyCoach(token: String, request: CoachVerificationRequest) async throws -> CoachVerificationResponse {
        let url = APIConfig.endpoint("/coach-verification/verify-with-ai")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw APIError(statusCode: nil, message: "Invalid server response.")
        }
        
        #if DEBUG
        if let bodyStr = String(data: data, encoding: .utf8) {
            print("➡️ POST \(url.absoluteString)")
            print("⬅️ Status: \(http.statusCode) Body: \(bodyStr)")
        }
        #endif
        
        if (200..<300).contains(http.statusCode) {
            return try JSONDecoder().decode(CoachVerificationResponse.self, from: data)
        } else {
            if let apiErr = try? JSONDecoder().decode(APIError.self, from: data) {
                throw apiErr
            }
            throw APIError(statusCode: http.statusCode, message: "Failed to verify coach with AI")
        }
    }
    
    func uploadDocument(token: String, pickedImage: PickedImage) async throws -> String {
        let url = APIConfig.endpoint("/coach-verification/upload-document")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(pickedImage.fileName)\"\r\n")
        body.append("Content-Type: \(pickedImage.mimeType)\r\n\r\n")
        body.append(pickedImage.data)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")
        urlRequest.httpBody = body
        
        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw APIError(statusCode: nil, message: "Invalid server response.")
        }
        
        #if DEBUG
        if let bodyStr = String(data: data, encoding: .utf8) {
            print("➡️ POST \(url.absoluteString) [upload]")
            print("⬅️ Status: \(http.statusCode) Body: \(bodyStr)")
        }
        #endif
        
        if (200..<300).contains(http.statusCode) {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let urlString = json["url"] as? String {
                return urlString
            }
            throw APIError(statusCode: http.statusCode, message: "Missing URL in upload response")
        } else {
            if let apiErr = try? JSONDecoder().decode(APIError.self, from: data) {
                throw apiErr
            }
            throw APIError(statusCode: http.statusCode, message: "Failed to upload document")
        }
    }
}
