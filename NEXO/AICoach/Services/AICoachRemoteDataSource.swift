import Foundation
import Combine

protocol AICoachRemoteDataSourceProtocol {
    func getSuggestions(request: AISuggestionsRequest) -> AnyPublisher<AISuggestionsResponse, Error>
    func getPersonalizedTips(request: PersonalizedTipsRequest) -> AnyPublisher<PersonalizedTipsResponse, Error>
    func getYouTubeVideos(sportPreferences: [String]?, maxResults: Int?) -> AnyPublisher<YouTubeVideosResponse, Error>
}

final class AICoachRemoteDataSource: AICoachRemoteDataSourceProtocol {
    private let baseURL: URL
    private let decoder: JSONDecoder
    
    init(baseURL: URL = APIConfig.baseURL) {
        self.baseURL = baseURL
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }
    
    private func authToken() -> String? {
        AuthTokenManager.shared.getToken()
    }
    
    // MARK: - Suggestions
    func getSuggestions(request: AISuggestionsRequest) -> AnyPublisher<AISuggestionsResponse, Error> {
        guard let token = authToken() else {
            let error = APIError(statusCode: 401, message: "Unauthorized")
            return Fail(error: error).eraseToAnyPublisher()
        }
        let url = baseURL.appendingPathComponent("ai-coach/suggestions")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response in
                guard let http = response as? HTTPURLResponse else {
                    throw APIError(statusCode: nil, message: "Invalid response")
                }
                if (200..<300).contains(http.statusCode) {
                    if let json = String(data: data, encoding: .utf8) {
                        print("🌐 [AICoach] Suggestions response (\(http.statusCode)): \(json)")
                    }
                    return data
                }
                if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                    throw apiError
                }
                throw APIError(statusCode: http.statusCode, message: String(data: data, encoding: .utf8) ?? "Unknown error")
            }
            .decode(type: AISuggestionsResponse.self, decoder: decoder)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Personalized Tips
    func getPersonalizedTips(request: PersonalizedTipsRequest) -> AnyPublisher<PersonalizedTipsResponse, Error> {
        guard let token = authToken() else {
            let error = APIError(statusCode: 401, message: "Unauthorized")
            return Fail(error: error).eraseToAnyPublisher()
        }
        let url = baseURL.appendingPathComponent("ai-coach/personalized-tips")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response in
                guard let http = response as? HTTPURLResponse else {
                    throw APIError(statusCode: nil, message: "Invalid response")
                }
                if (200..<300).contains(http.statusCode) {
                    return data
                }
                if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                    throw apiError
                }
                throw APIError(statusCode: http.statusCode, message: String(data: data, encoding: .utf8) ?? "Unknown error")
            }
            .decode(type: PersonalizedTipsResponse.self, decoder: decoder)
            .eraseToAnyPublisher()
    }
    
    // MARK: - YouTube Videos
    func getYouTubeVideos(sportPreferences: [String]?, maxResults: Int?) -> AnyPublisher<YouTubeVideosResponse, Error> {
        guard let token = authToken() else {
            let error = APIError(statusCode: 401, message: "Unauthorized")
            return Fail(error: error).eraseToAnyPublisher()
        }
        var components = URLComponents(url: baseURL.appendingPathComponent("ai-coach/youtube-videos"), resolvingAgainstBaseURL: false)!
        var queryItems: [URLQueryItem] = []
        if let prefs = sportPreferences, !prefs.isEmpty {
            queryItems.append(URLQueryItem(name: "sportPreferences", value: prefs.joined(separator: ",")))
        }
        if let maxResults = maxResults {
            queryItems.append(URLQueryItem(name: "maxResults", value: String(maxResults)))
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components.url else {
            let error = APIError(statusCode: nil, message: "Invalid URL")
            return Fail(error: error).eraseToAnyPublisher()
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let http = response as? HTTPURLResponse else {
                    throw APIError(statusCode: nil, message: "Invalid response")
                }
                if (200..<300).contains(http.statusCode) {
                    if let json = String(data: data, encoding: .utf8) {
                        print("🌐 [AICoach] YouTube videos response (\(http.statusCode)): \(json)")
                    }
                    return data
                }
                if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                    throw apiError
                }
                throw APIError(statusCode: http.statusCode, message: String(data: data, encoding: .utf8) ?? "Unknown error")
            }
            .decode(type: YouTubeVideosResponse.self, decoder: decoder)
            .eraseToAnyPublisher()
    }
}
