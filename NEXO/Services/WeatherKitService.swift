//
//  WeatherKitService.swift
//  NEXO
//
//  Created by ROCCO 4X on 13/11/2025.
//

import Foundation
import WeatherKit
import CoreLocation
import Combine

@available(iOS 16.0, *)
class WeatherKitService: NSObject, ObservableObject {
    private let weatherService = WeatherService.shared
    private let locationManager = CLLocationManager()
    
    @Published var currentWeather: Weather?
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentLocation: CLLocation?
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    // MARK: - Public Methods
    
    func requestLocationAndWeather() async {
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        // Request location permission if needed
        if locationManager.authorizationStatus == .notDetermined {
            await MainActor.run {
                self.locationManager.requestWhenInUseAuthorization()
            }
        }
        
        // Get current location
        if let location = await getCurrentLocation() {
            await fetchWeather(for: location)
        } else {
            // Fallback to a default location (e.g., San Francisco)
            let defaultLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
            await fetchWeather(for: defaultLocation)
        }
    }
    
    private func getCurrentLocation() async -> CLLocation? {
        return await withCheckedContinuation { continuation in
            switch locationManager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                if let location = locationManager.location {
                    continuation.resume(returning: location)
                } else {
                    locationManager.requestLocation()
                    // Will be handled in delegate method
                    continuation.resume(returning: nil)
                }
            default:
                continuation.resume(returning: nil)
            }
        }
    }
    
    private func fetchWeather(for location: CLLocation) async {
        do {
            let weather = try await weatherService.weather(for: location)
            
            await MainActor.run {
                self.currentWeather = weather
                self.currentLocation = location
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to fetch weather: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Weather Analysis for AI
    
    func getWeatherAnalysisForAI() -> String {
        guard let weather = currentWeather else {
            return "Weather data not available"
        }
        
        let current = weather.currentWeather
        let temperature = Int(current.temperature.converted(to: .fahrenheit).value)
        let condition = current.condition.description
        let humidity = Int(current.humidity * 100)
        let windSpeed = Int(current.wind.speed.converted(to: .milesPerHour).value)
        
        var analysis = """
        Current Weather Conditions:
        - Temperature: \(temperature)°F
        - Condition: \(condition)
        - Humidity: \(humidity)%
        - Wind Speed: \(windSpeed) mph
        """
        
        // Add weather-based activity recommendations
        if temperature >= 70 && temperature <= 85 && !isRaining(current.condition) {
            analysis += "\n- Perfect weather for outdoor activities"
        } else if temperature < 50 {
            analysis += "\n- Cold weather - consider indoor workouts or warm clothing for outdoor activities"
        } else if isRaining(current.condition) {
            analysis += "\n- Rainy conditions - indoor activities recommended"
        } else if temperature > 85 {
            analysis += "\n- Hot weather - stay hydrated and consider early morning or evening workouts"
        }
        
        return analysis
    }
    
    private func isRaining(_ condition: WeatherCondition) -> Bool {
        switch condition {
        case .rain, .drizzle, .heavyRain, .isolatedThunderstorms, .scatteredThunderstorms, .strongStorms:
            return true
        default:
            return false
        }
    }
    
    // MARK: - UI Helper Methods
    
    func getWeatherInfo() -> WeatherInfo? {
        guard let weather = currentWeather else { return nil }
        
        let current = weather.currentWeather
        let temperature = Int(current.temperature.converted(to: .fahrenheit).value)
        let condition = current.condition.description
        
        let icon = getWeatherIcon(for: current.condition)
        let description = getWeatherDescription(for: current.condition, temperature: temperature)
        
        return WeatherInfo(
            temperature: temperature,
            condition: condition.lowercased(),
            description: description,
            icon: icon
        )
    }
    
    private func getWeatherIcon(for condition: WeatherCondition) -> String {
        switch condition {
        case .clear, .mostlyClear:
            return "sun.max.fill"
        case .partlyCloudy:
            return "cloud.sun.fill"
        case .mostlyCloudy, .cloudy:
            return "cloud.fill"
        case .rain, .drizzle:
            return "cloud.rain.fill"
        case .heavyRain:
            return "cloud.heavyrain.fill"
        case .snow:
            return "cloud.snow.fill"
        case .isolatedThunderstorms, .scatteredThunderstorms, .strongStorms:
            return "cloud.bolt.fill"
        default:
            return "sun.max.fill"
        }
    }
    
    private func getWeatherDescription(for condition: WeatherCondition, temperature: Int) -> String {
        switch condition {
        case .clear, .mostlyClear:
            if temperature >= 70 && temperature <= 85 {
                return "perfect for outdoor training"
            } else if temperature > 85 {
                return "hot - stay hydrated during workouts"
            } else {
                return "clear skies for outdoor activities"
            }
        case .partlyCloudy:
            return "great conditions for any workout"
        case .mostlyCloudy, .cloudy:
            return "good for outdoor activities"
        case .rain, .drizzle, .heavyRain:
            return "consider indoor workouts today"
        case .snow:
            return "winter sports weather!"
        case .isolatedThunderstorms, .scatteredThunderstorms, .strongStorms:
            return "stay indoors - storms expected"
        default:
            return "check conditions before outdoor workouts"
        }
    }
}

// MARK: - CLLocationManagerDelegate
@available(iOS 16.0, *)
extension WeatherKitService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task {
            await fetchWeather(for: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task {
            await MainActor.run {
                self.error = "Location error: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            Task {
                await MainActor.run {
                    self.error = "Location access denied. Using default location."
                }
                // Use default location
                let defaultLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
                await fetchWeather(for: defaultLocation)
            }
        default:
            break
        }
    }
}

// MARK: - Fallback for iOS < 16
class LegacyWeatherService: ObservableObject {
    @Published var weatherInfo: WeatherInfo?
    
    init() {
        // Provide fallback weather data for older iOS versions
        weatherInfo = WeatherInfo(
            temperature: 72,
            condition: "sunny",
            description: "great for outdoor activities",
            icon: "sun.max.fill"
        )
    }
    
    func getWeatherAnalysisForAI() -> String {
        return "Weather data not available on this iOS version"
    }
}
