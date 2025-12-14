import Foundation

struct StravaConnectionResult {
    let success: Bool
    let message: String
}

struct StravaOAuthError: LocalizedError {
    let code: String
    let description: String

    var errorDescription: String? {
        description
    }
}

extension Notification.Name {
    static let stravaOAuthCompleted = Notification.Name("StravaOAuthCompleted")
}

final class StravaOAuthHandler {
    static let shared = StravaOAuthHandler()

    private init() {}

    // Handle deep link like nexofitness://strava/callback?code=...
    @discardableResult
    func handleDeepLink(_ url: URL) -> Bool {
        guard url.scheme == StravaConfig.redirectScheme else { return false }
        guard url.host == "strava", url.path == "/callback" else { return false }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            notifyFailure(StravaOAuthError(code: "invalid_url", description: "Invalid Strava callback URL."))
            return true
        }

        if let errorCode = queryItems.first(where: { $0.name == "error" })?.value {
            let description = queryItems.first(where: { $0.name == "error_description" })?.value ?? "Strava authorization failed."
            let error = StravaOAuthError(code: errorCode, description: description)
            notifyFailure(error)
            return true
        }

        guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
            let error = StravaOAuthError(code: "missing_code", description: "No authorization code received from Strava.")
            notifyFailure(error)
            return true
        }

        exchangeCodeForToken(code: code)
        return true
    }

    // MARK: - Exchange code for token via backend

    private func exchangeCodeForToken(code: String) {
        guard let token = AuthTokenManager.shared.getToken(), !token.isEmpty else {
            let error = StravaOAuthError(code: "not_authenticated", description: "You must be logged in to connect Strava.")
            notifyFailure(error)
            return
        }

        let url = APIConfig.endpoint("/strava/oauth/callback")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["code": code]
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            notifyFailure(error)
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                self.notifyFailure(error)
                return
            }

            guard let http = response as? HTTPURLResponse else {
                self.notifyFailure(StravaOAuthError(code: "invalid_response", description: "Invalid server response."))
                return
            }

            guard let data = data else {
                self.notifyFailure(StravaOAuthError(code: "empty_response", description: "Empty response from server."))
                return
            }

            if !(200..<300).contains(http.statusCode) {
                var message = "Failed to connect Strava account (status: \(http.statusCode))."
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let serverMessage = json["message"] as? String {
                    message = serverMessage
                }
                let error = StravaOAuthError(code: "server_error", description: message)
                self.notifyFailure(error)
                return
            }

            var message = "Strava account connected successfully."
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let serverMessage = json["message"] as? String {
                message = serverMessage
            }

            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .stravaOAuthCompleted,
                    object: StravaConnectionResult(success: true, message: message)
                )
            }
        }.resume()
    }

    private func notifyFailure(_ error: Error) {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .stravaOAuthCompleted,
                object: StravaConnectionResult(success: false, message: message)
            )
        }
    }
}
