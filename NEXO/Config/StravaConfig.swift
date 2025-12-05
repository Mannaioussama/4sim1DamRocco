import Foundation

enum StravaConfig {
    // TODO: Replace with your real Strava Client ID from https://www.strava.com/settings/api
    // Example: static let clientId = "12345"
    static let clientId: String = "YOUR_REAL_STRAVA_CLIENT_ID"
    
    // This must match the URL Scheme registered in your Xcode project Info.plist
    // and the Redirect URI configured in the Strava developer portal.
    // According to the iOS guide, we use nexofitness://strava/callback
    static let redirectScheme: String = "nexofitness"
    
    static var redirectURI: String {
        return "\(redirectScheme)://strava/callback"
    }
}
