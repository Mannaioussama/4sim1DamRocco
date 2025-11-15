//
//  GeminiAIService.swift
//  NEXO
//
//  Created by ROCCO 4X on 13/11/2025.
//

import Foundation
import Combine

// MARK: - AI Response Models
struct AICoachResponse {
    let suggestions: [AISuggestion]
    let tips: [AITip]
    let motivationalMessage: String
    let analysis: String
    let recommendations: [String]
}

struct AISuggestion {
    let id: UUID = UUID()
    let title: String
    let description: String
    let activityType: String
    let duration: Int // minutes
    let intensity: String // "Low", "Medium", "High"
    let matchScore: Int // 0-100
    let reasoning: String
    let icon: String
    let time: String
    let participants: Int
}

struct AITip {
    let id: UUID = UUID()
    let title: String
    let description: String
    let category: String
    let priority: String // "High", "Medium", "Low"
    let icon: String
    let actionable: Bool
}

// MARK: - Gemini API Models
struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig?
    let safetySettings: [GeminiSafetySetting]?
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

struct GeminiGenerationConfig: Codable {
    let temperature: Double
    let topK: Int
    let topP: Double
    let maxOutputTokens: Int
}

struct GeminiSafetySetting: Codable {
    let category: String
    let threshold: String
}

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
    let finishReason: String?
    let safetyRatings: [GeminiSafetyRating]?
}

struct GeminiSafetyRating: Codable {
    let category: String
    let probability: String
}

class GeminiAIService: ObservableObject {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
    private let session = URLSession.shared
    
    @Published var isLoading = false
    @Published var lastResponse: AICoachResponse?
    @Published var error: String?
    
    init() {
        self.apiKey = APIConfiguration.geminiAPIKey
    }
    
    // MARK: - Main Analysis Function
    func analyzeHealthDataAndGenerateRecommendations(
        healthMetrics: HealthMetrics,
        recentWorkouts: [WorkoutSession],
        weeklyTrends: [HealthMetrics],
        userPreferences: [String] = [],
        weatherAnalysis: String = "",
        availableActivities: [Activity] = [],
        activitySummary: String = ""
    ) async -> AICoachResponse? {
        
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        let prompt = buildAnalysisPrompt(
            healthMetrics: healthMetrics,
            recentWorkouts: recentWorkouts,
            weeklyTrends: weeklyTrends,
            userPreferences: userPreferences,
            weatherAnalysis: weatherAnalysis,
            availableActivities: availableActivities,
            activitySummary: activitySummary
        )
        
        do {
            let response = try await callGeminiAPI(prompt: prompt)
            let aiResponse = parseGeminiResponse(response)
            
            await MainActor.run {
                self.lastResponse = aiResponse
                self.isLoading = false
            }
            
            return aiResponse
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
            return nil
        }
    }
    
    // MARK: - Prompt Building
    private func buildAnalysisPrompt(
        healthMetrics: HealthMetrics,
        recentWorkouts: [WorkoutSession],
        weeklyTrends: [HealthMetrics],
        userPreferences: [String],
        weatherAnalysis: String,
        availableActivities: [Activity],
        activitySummary: String
    ) -> String {
        
        let healthSummary = """
        Current Health Metrics (Today):
        - Steps: \(healthMetrics.steps)
        - Active Calories: \(healthMetrics.activeCalories) kcal
        - Workout Minutes: \(healthMetrics.workoutMinutes) min
        - Heart Rate: \(healthMetrics.heartRate.map { String(format: "%.0f bpm", $0) } ?? "N/A")
        - Sleep: \(healthMetrics.sleepHours.map { String(format: "%.1f hours", $0) } ?? "N/A")
        - Weight: \(healthMetrics.bodyWeight.map { String(format: "%.1f kg", $0) } ?? "N/A")
        - Resting HR: \(healthMetrics.restingHeartRate.map { String(format: "%.0f bpm", $0) } ?? "N/A")
        - VO2 Max: \(healthMetrics.vo2Max.map { String(format: "%.1f ml/kg/min", $0) } ?? "N/A")
        """
        
        let workoutSummary = recentWorkouts.isEmpty ? "No recent workouts" : 
        recentWorkouts.prefix(5).map { workout in
            let activityName = workout.type.name
            let duration = Int(workout.duration / 60)
            let calories = Int(workout.calories)
            let date = DateFormatter.shortDate.string(from: workout.startDate)
            return "- \(date): \(activityName), \(duration) min, \(calories) kcal"
        }.joined(separator: "\n")
        
        let trendSummary = weeklyTrends.isEmpty ? "No trend data available" :
        "Weekly Trends:\n" + weeklyTrends.map { trend in
            let date = DateFormatter.shortDate.string(from: trend.date)
            return "- \(date): \(trend.steps) steps, \(trend.activeCalories) kcal, \(trend.workoutMinutes) min"
        }.joined(separator: "\n")
        
        let preferences = userPreferences.isEmpty ? "No specific preferences" : userPreferences.joined(separator: ", ")
        
        return """
        You are an expert AI fitness coach analyzing health data to provide personalized recommendations. 
        
        User's Health Data:
        \(healthSummary)
        
        Recent Workouts (Last 7 days):
        \(workoutSummary)
        
        \(trendSummary)
        
        User Preferences: \(preferences)
        
        \(weatherAnalysis.isEmpty ? "" : "\n\(weatherAnalysis)\n")
        
        \(activitySummary.isEmpty ? "" : "\n\(activitySummary)\n")
        
        Available Activities to Recommend:
        \(formatActivitiesForAI(availableActivities))
        
        Please analyze this data and provide SPECIFIC recommendations from the available activities above:
        
        1. SUGGESTIONS (3-4 specific activity recommendations):
        Format each as: "SUGGESTION: [Title] | [Description] | [ActivityType] | [Duration in minutes] | [Intensity: Low/Medium/High] | [Match score 0-100] | [Reasoning] | [Emoji icon] | [Suggested time] | [Number of participants]"
        
        2. TIPS (3-4 actionable fitness/health tips):
        Format each as: "TIP: [Title] | [Description] | [Category] | [Priority: High/Medium/Low] | [Emoji icon] | [Actionable: true/false]"
        
        3. MOTIVATIONAL_MESSAGE: A short, encouraging message (max 50 characters)
        
        4. ANALYSIS: A brief analysis of their current fitness state (2-3 sentences)
        
        5. RECOMMENDATIONS: 3-4 general recommendations for improvement
        
        Consider:
        - Current fitness level and activity patterns
        - Recovery needs based on recent workouts
        - Weather and time of day for outdoor activities
        - Social aspects (group vs individual activities)
        - Progressive overload and variety
        - Injury prevention
        - Work-life balance
        
        Be specific, actionable, and encouraging. Focus on realistic, achievable goals.
        """
    }
    
    // MARK: - API Communication
    private func callGeminiAPI(prompt: String) async throws -> String {
        guard APIConfiguration.isGeminiConfigured else {
            throw GeminiError.missingAPIKey
        }
        
        let request = GeminiRequest(
            contents: [
                GeminiContent(parts: [GeminiPart(text: prompt)])
            ],
            generationConfig: GeminiGenerationConfig(
                temperature: 0.7,
                topK: 40,
                topP: 0.95,
                maxOutputTokens: 2048
            ),
            safetySettings: [
                GeminiSafetySetting(category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_MEDIUM_AND_ABOVE"),
                GeminiSafetySetting(category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_MEDIUM_AND_ABOVE"),
                GeminiSafetySetting(category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_MEDIUM_AND_ABOVE"),
                GeminiSafetySetting(category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_MEDIUM_AND_ABOVE")
            ]
        )
        
        var urlRequest = URLRequest(url: URL(string: "\(baseURL)?key=\(apiKey)")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestData = try JSONEncoder().encode(request)
        urlRequest.httpBody = requestData
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("🤖 Invalid HTTP response")
            throw GeminiError.invalidResponse
        }
        
        print("🤖 API Response Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "No error body"
            print("🤖 API Error \(httpResponse.statusCode): \(errorBody)")
            throw GeminiError.apiError(httpResponse.statusCode)
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let candidate = geminiResponse.candidates.first,
              let text = candidate.content.parts.first?.text else {
            throw GeminiError.noContent
        }
        
        return text
    }
    
    private func formatActivitiesForAI(_ activities: [Activity]) -> String {
        if activities.isEmpty {
            return "No activities currently available."
        }
        
        return activities.enumerated().map { index, activity in
            let spotsLeft = activity.spotsTotal - activity.spotsTaken
            return """
            \(index + 1). \(activity.title)
               - Sport: \(activity.sportType) \(activity.sportIcon)
               - Host: \(activity.hostName)
               - When: \(activity.date) at \(activity.time)
               - Where: \(activity.location) (\(activity.distance))
               - Level: \(activity.level)
               - Spots: \(spotsLeft)/\(activity.spotsTotal) available
            """
        }.joined(separator: "\n\n")
    }
    
    // MARK: - Response Parsing
    private func parseGeminiResponse(_ response: String) -> AICoachResponse {
        var suggestions: [AISuggestion] = []
        var tips: [AITip] = []
        var motivationalMessage = "Keep pushing forward! 💪"
        var analysis = "Your fitness journey is progressing well."
        var recommendations: [String] = []
        
        let lines = response.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.hasPrefix("SUGGESTION:") {
                if let suggestion = parseSuggestionLine(trimmedLine) {
                    suggestions.append(suggestion)
                }
            } else if trimmedLine.hasPrefix("TIP:") {
                if let tip = parseTipLine(trimmedLine) {
                    tips.append(tip)
                }
            } else if trimmedLine.hasPrefix("MOTIVATIONAL_MESSAGE:") {
                motivationalMessage = String(trimmedLine.dropFirst("MOTIVATIONAL_MESSAGE:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmedLine.hasPrefix("ANALYSIS:") {
                analysis = String(trimmedLine.dropFirst("ANALYSIS:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmedLine.hasPrefix("RECOMMENDATIONS:") {
                // Parse recommendations that follow
                continue
            } else if trimmedLine.hasPrefix("- ") && !trimmedLine.contains("SUGGESTION:") && !trimmedLine.contains("TIP:") {
                let recommendation = String(trimmedLine.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
                if !recommendation.isEmpty {
                    recommendations.append(recommendation)
                }
            }
        }
        
        // Fallback suggestions if parsing fails
        if suggestions.isEmpty {
            suggestions = getDefaultSuggestions()
        }
        
        if tips.isEmpty {
            tips = getDefaultTips()
        }
        
        return AICoachResponse(
            suggestions: suggestions,
            tips: tips,
            motivationalMessage: motivationalMessage,
            analysis: analysis,
            recommendations: recommendations.isEmpty ? ["Stay consistent with your workouts", "Focus on proper form", "Get adequate rest"] : recommendations
        )
    }
    
    private func parseSuggestionLine(_ line: String) -> AISuggestion? {
        let content = String(line.dropFirst("SUGGESTION:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
        let components = content.components(separatedBy: " | ")
        
        guard components.count >= 10 else { return nil }
        
        return AISuggestion(
            title: components[0],
            description: components[1],
            activityType: components[2],
            duration: Int(components[3]) ?? 30,
            intensity: components[4],
            matchScore: Int(components[5]) ?? 80,
            reasoning: components[6],
            icon: components[7],
            time: components[8],
            participants: Int(components[9]) ?? 1
        )
    }
    
    private func parseTipLine(_ line: String) -> AITip? {
        let content = String(line.dropFirst("TIP:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
        let components = content.components(separatedBy: " | ")
        
        guard components.count >= 6 else { return nil }
        
        return AITip(
            title: components[0],
            description: components[1],
            category: components[2],
            priority: components[3],
            icon: components[4],
            actionable: components[5].lowercased() == "true"
        )
    }
    
    // MARK: - Fallback Data
    private func getDefaultSuggestions() -> [AISuggestion] {
        return [
            AISuggestion(
                title: "Morning Walk",
                description: "Start your day with a refreshing 30-minute walk",
                activityType: "Walking",
                duration: 30,
                intensity: "Low",
                matchScore: 85,
                reasoning: "Great for building daily activity habits",
                icon: "🚶",
                time: "Morning",
                participants: 1
            ),
            AISuggestion(
                title: "Strength Training",
                description: "Build muscle with a focused strength session",
                activityType: "Strength",
                duration: 45,
                intensity: "Medium",
                matchScore: 78,
                reasoning: "Important for overall fitness balance",
                icon: "💪",
                time: "Evening",
                participants: 1
            )
        ]
    }
    
    private func getDefaultTips() -> [AITip] {
        return [
            AITip(
                title: "Stay Hydrated",
                description: "Drink water before, during, and after workouts",
                category: "Health",
                priority: "High",
                icon: "💧",
                actionable: true
            ),
            AITip(
                title: "Warm Up Properly",
                description: "Always start with 5-10 minutes of light activity",
                category: "Safety",
                priority: "High",
                icon: "🔥",
                actionable: true
            )
        ]
    }
}

// MARK: - Error Handling
enum GeminiError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case apiError(Int)
    case noContent
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Gemini API key is missing. Please add your API key to the service."
        case .invalidResponse:
            return "Invalid response from Gemini API"
        case .apiError(let code):
            return "Gemini API error with status code: \(code)"
        case .noContent:
            return "No content received from Gemini API"
        }
    }
}

// MARK: - Extensions
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter
    }()
}
