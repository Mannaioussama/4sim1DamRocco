import Foundation

enum StravaConfig {
 
    static let clientId: String = "188930"
    
    static let redirectScheme: String = "nexofitness"

    static let backendRedirectURI: String = "https://apinest-production.up.railway.app/strava/callback"
    
    static var appCallbackURL: String {
        return "\(redirectScheme)://strava/callback"
    }
}
