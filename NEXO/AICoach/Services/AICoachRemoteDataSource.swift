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
    
    // Simple disk caches for offline fallback
    private var suggestionsCacheURL: URL {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent("ai_suggestions_cache.json")
    }
    
    private var tipsCacheURL: URL {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent("ai_tips_cache.json")
    }
    
    private var videosCacheURL: URL {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent("ai_videos_cache.json")
    }
    
    init(baseURL: URL = APIConfig.baseURL) {
        self.baseURL = baseURL
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }
    
    private func authToken() -> String? {
        AuthTokenManager.shared.getToken()
    }
    
    // MARK: - Cache Helpers
    private func saveData(_ data: Data, to url: URL, label: String) {
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            #if DEBUG
            print("❌ [AICoach] Failed to cache \(label): \(error)")
            #endif
        }
    }
    
    private func loadData(from url: URL, label: String) -> Data? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            return try Data(contentsOf: url)
        } catch {
            #if DEBUG
            print("❌ [AICoach] Failed to load cached \(label): \(error)")
            #endif
            return nil
        }
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
            .tryMap { [weak self] data, response in
                guard let http = response as? HTTPURLResponse else {
                    throw APIError(statusCode: nil, message: "Invalid response")
                }
                if (200..<300).contains(http.statusCode) {
                    if let json = String(data: data, encoding: .utf8) {
                        print("🌐 [AICoach] Suggestions response (\(http.statusCode)): \(json)")
                    }
                    self?.saveData(data, to: self?.suggestionsCacheURL ?? URL(fileURLWithPath: "/dev/null"), label: "suggestions")
                    return data
                }
                if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                    throw apiError
                }
                throw APIError(statusCode: http.statusCode, message: String(data: data, encoding: .utf8) ?? "Unknown error")
            }
            .decode(type: AISuggestionsResponse.self, decoder: decoder)
            .catch { [weak self] error -> AnyPublisher<AISuggestionsResponse, Error> in
                guard let self = self,
                      let data = self.loadData(from: self.suggestionsCacheURL, label: "suggestions"),
                      let cached = try? self.decoder.decode(AISuggestionsResponse.self, from: data) else {
                    return Fail(error: error).eraseToAnyPublisher()
                }
                #if DEBUG
                print("ℹ️ [AICoach] Returning cached suggestions due to error: \(error)")
                #endif
                return Just(cached).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
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
            .tryMap { [weak self] data, response in
                guard let http = response as? HTTPURLResponse else {
                    throw APIError(statusCode: nil, message: "Invalid response")
                }
                if (200..<300).contains(http.statusCode) {
                    self?.saveData(data, to: self?.tipsCacheURL ?? URL(fileURLWithPath: "/dev/null"), label: "tips")
                    return data
                }
                if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                    throw apiError
                }
                throw APIError(statusCode: http.statusCode, message: String(data: data, encoding: .utf8) ?? "Unknown error")
            }
            .decode(type: PersonalizedTipsResponse.self, decoder: decoder)
            .catch { [weak self] error -> AnyPublisher<PersonalizedTipsResponse, Error> in
                guard let self = self,
                      let data = self.loadData(from: self.tipsCacheURL, label: "tips"),
                      let cached = try? self.decoder.decode(PersonalizedTipsResponse.self, from: data) else {
                    return Fail(error: error).eraseToAnyPublisher()
                }
                #if DEBUG
                print("ℹ️ [AICoach] Returning cached tips due to error: \(error)")
                #endif
                return Just(cached).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
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
            .tryMap { [weak self] data, response in
                guard let http = response as? HTTPURLResponse else {
                    throw APIError(statusCode: nil, message: "Invalid response")
                }
                if (200..<300).contains(http.statusCode) {
                    if let json = String(data: data, encoding: .utf8) {
                        print("🌐 [AICoach] YouTube videos response (\(http.statusCode)): \(json)")
                    }
                    self?.saveData(data, to: self?.videosCacheURL ?? URL(fileURLWithPath: "/dev/null"), label: "videos")
                    return data
                }
                if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                    throw apiError
                }
                throw APIError(statusCode: http.statusCode, message: String(data: data, encoding: .utf8) ?? "Unknown error")
            }
            .decode(type: YouTubeVideosResponse.self, decoder: decoder)
            .catch { [weak self] error -> AnyPublisher<YouTubeVideosResponse, Error> in
                guard let self = self,
                      let data = self.loadData(from: self.videosCacheURL, label: "videos"),
                      let cached = try? self.decoder.decode(YouTubeVideosResponse.self, from: data) else {
                    return Fail(error: error).eraseToAnyPublisher()
                }
                #if DEBUG
                print("ℹ️ [AICoach] Returning cached videos due to error: \(error)")
                #endif
                return Just(cached).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
