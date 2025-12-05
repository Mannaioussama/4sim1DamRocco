//
//  HealthKitManager.swift
//  NEXO
//
//  Created by ROCCO 4X on 13/11/2025.
//

import Foundation
import HealthKit
import Combine

// MARK: - Health Data Models
struct HealthMetrics {
    let steps: Int
    let activeCalories: Int
    let heartRate: Double?
    let workoutMinutes: Int
    let sleepHours: Double?
    let bodyWeight: Double?
    let restingHeartRate: Double?
    let vo2Max: Double?
    let date: Date
}

struct WorkoutSession {
    let id: UUID
    let type: HKWorkoutActivityType
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let calories: Double
    let distance: Double?
    let averageHeartRate: Double?
    let maxHeartRate: Double?
}

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var currentMetrics: HealthMetrics?
    @Published var recentWorkouts: [WorkoutSession] = []
    @Published var weeklyTrends: [HealthMetrics] = []
    
    // MARK: - Health Data Types
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
        HKObjectType.quantityType(forIdentifier: .vo2Max)!,
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKObjectType.workoutType()
    ]
    
    // MARK: - Authorization
    func requestAuthorization() async {
        print("🏥 Starting HealthKit authorization...")
        
        // For free developer accounts, always use mock data
        print("🏥 Using mock data for free developer account")
        await createMockData()
        return
        
        // Real HealthKit code (commented out for free accounts)
        /*
        guard HKHealthStore.isHealthDataAvailable() else {
            print("🏥 HealthKit not available on this device")
            await createMockData()
            return
        }
        
        print("🏥 Requesting authorization for \(readTypes.count) data types")
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            
            // Check authorization status for each type
            var authorizedCount = 0
            for type in readTypes {
                let status = healthStore.authorizationStatus(for: type)
                print("🏥 \(type): \(status.rawValue)")
                if status == .sharingAuthorized {
                    authorizedCount += 1
                }
            }
            
            let isAuth = authorizedCount > 0
            print("🏥 Authorization result: \(authorizedCount)/\(readTypes.count) types authorized")
            
            await MainActor.run {
                self.isAuthorized = isAuth
            }
            
            if isAuth {
                await loadAllHealthData()
            } else {
                await createMockData()
            }
        } catch {
            print("🏥 HealthKit authorization failed: \(error)")
            print("🏥 Using mock data instead...")
            await createMockData()
        }
        */
    }
    
    // MARK: - Data Loading
    func loadAllHealthData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadCurrentMetrics() }
            group.addTask { await self.loadRecentWorkouts() }
            group.addTask { await self.loadWeeklyTrends() }
        }
    }
    
    private func loadCurrentMetrics() async {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        async let steps = fetchSteps(from: startOfDay, to: now)
        async let calories = fetchActiveCalories(from: startOfDay, to: now)
        async let heartRate = fetchLatestHeartRate()
        async let workoutMinutes = fetchWorkoutMinutes(from: startOfDay, to: now)
        async let sleepHours = fetchSleepHours(from: calendar.date(byAdding: .day, value: -1, to: startOfDay)!, to: startOfDay)
        async let bodyWeight = fetchLatestBodyWeight()
        async let restingHR = fetchLatestRestingHeartRate()
        async let vo2 = fetchLatestVO2Max()
        
        let metrics = HealthMetrics(
            steps: await steps,
            activeCalories: await calories,
            heartRate: await heartRate,
            workoutMinutes: await workoutMinutes,
            sleepHours: await sleepHours,
            bodyWeight: await bodyWeight,
            restingHeartRate: await restingHR,
            vo2Max: await vo2,
            date: now
        )
        
        await MainActor.run {
            self.currentMetrics = metrics
        }
    }
    
    private func loadRecentWorkouts() async {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
        
        let workouts = await fetchWorkouts(from: startDate, to: endDate)
        
        await MainActor.run {
            self.recentWorkouts = workouts
        }
    }
    
    private func loadWeeklyTrends() async {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
        
        var trends: [HealthMetrics] = []
        
        for i in 0..<7 {
            let dayStart = calendar.date(byAdding: .day, value: i, to: startDate)!
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            async let steps = fetchSteps(from: dayStart, to: dayEnd)
            async let calories = fetchActiveCalories(from: dayStart, to: dayEnd)
            async let workoutMinutes = fetchWorkoutMinutes(from: dayStart, to: dayEnd)
            
            let metrics = HealthMetrics(
                steps: await steps,
                activeCalories: await calories,
                heartRate: nil,
                workoutMinutes: await workoutMinutes,
                sleepHours: nil,
                bodyWeight: nil,
                restingHeartRate: nil,
                vo2Max: nil,
                date: dayStart
            )
            
            trends.append(metrics)
        }
        
        await MainActor.run {
            self.weeklyTrends = trends
        }
    }
    
    // MARK: - Individual Data Fetchers
    private func fetchSteps(from startDate: Date, to endDate: Date) async -> Int {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            // Handled in continuation
        }
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchActiveCalories(from startDate: Date, to endDate: Date) async -> Int {
        guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let calories = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                continuation.resume(returning: Int(calories))
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchLatestHeartRate() async -> Double? {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return nil }
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                continuation.resume(returning: heartRate)
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchWorkoutMinutes(from startDate: Date, to endDate: Date) async -> Int {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: 0)
                    return
                }
                
                let totalMinutes = workouts.reduce(0) { total, workout in
                    return total + Int(workout.duration / 60)
                }
                continuation.resume(returning: totalMinutes)
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchSleepHours(from startDate: Date, to endDate: Date) async -> Double? {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                guard let sleepSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let totalSleepTime = sleepSamples.reduce(0.0) { total, sample in
                    if sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue || sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue {
                        return total + sample.endDate.timeIntervalSince(sample.startDate)
                    }
                    return total
                }
                
                continuation.resume(returning: totalSleepTime / 3600) // Convert to hours
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchLatestBodyWeight() async -> Double? {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return nil }
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let weight = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                continuation.resume(returning: weight)
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchLatestRestingHeartRate() async -> Double? {
        guard let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return nil }
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: restingHRType, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let restingHR = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                continuation.resume(returning: restingHR)
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchLatestVO2Max() async -> Double? {
        guard let vo2MaxType = HKQuantityType.quantityType(forIdentifier: .vo2Max) else { return nil }
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: vo2MaxType, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let vo2Max = sample.quantity.doubleValue(for: HKUnit(from: "ml/kg*min"))
                continuation.resume(returning: vo2Max)
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchWorkouts(from startDate: Date, to endDate: Date) async -> [WorkoutSession] {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, _ in
                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let workoutSessions = workouts.map { workout in
                    WorkoutSession(
                        id: UUID(),
                        type: workout.workoutActivityType,
                        startDate: workout.startDate,
                        endDate: workout.endDate,
                        duration: workout.duration,
                        calories: workout.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()) ?? 0,
                        distance: workout.totalDistance?.doubleValue(for: HKUnit.meter()) ?? nil,
                        averageHeartRate: nil, // Would need separate query for heart rate data
                        maxHeartRate: nil
                    )
                }
                
                continuation.resume(returning: workoutSessions)
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Public Methods
    func refreshData() async {
        await loadAllHealthData()
    }
    
    // MARK: - Mock Data (for free developer accounts)
    private func createMockData() async {
        print("🏥 Creating mock health data...")
        
        let mockMetrics = HealthMetrics(
            steps: 8547,
            activeCalories: 420,
            heartRate: 72.0,
            workoutMinutes: 45,
            sleepHours: 7.5,
            bodyWeight: 70.0,
            restingHeartRate: 65.0,
            vo2Max: 42.0,
            date: Date()
        )
        
        let mockWorkouts = [
            WorkoutSession(
                id: UUID(),
                type: .running,
                startDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                endDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!.addingTimeInterval(1800),
                duration: 1800,
                calories: 250,
                distance: 5000,
                averageHeartRate: 145,
                maxHeartRate: 165
            ),
            WorkoutSession(
                id: UUID(),
                type: .cycling,
                startDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                endDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!.addingTimeInterval(2700),
                duration: 2700,
                calories: 380,
                distance: 15000,
                averageHeartRate: 135,
                maxHeartRate: 155
            )
        ]
        
        let mockTrends = (0..<7).map { dayOffset in
            HealthMetrics(
                steps: Int.random(in: 6000...12000),
                activeCalories: Int.random(in: 300...600),
                heartRate: nil,
                workoutMinutes: Int.random(in: 0...90),
                sleepHours: nil,
                bodyWeight: nil,
                restingHeartRate: nil,
                vo2Max: nil,
                date: Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!
            )
        }
        
        await MainActor.run {
            self.currentMetrics = mockMetrics
            self.recentWorkouts = mockWorkouts
            self.weeklyTrends = mockTrends
            self.isAuthorized = true
        }
        
        print("🏥 Mock data created successfully")
    }
    
    func getHealthSummary() -> String {
        guard let metrics = currentMetrics else { return "No health data available" }
        
        return """
        Today's Health Summary:
        - Steps: \(metrics.steps)
        - Active Calories: \(metrics.activeCalories) kcal
        - Workout Minutes: \(metrics.workoutMinutes) min
        - Heart Rate: \(metrics.heartRate.map { String(format: "%.0f bpm", $0) } ?? "N/A")
        - Sleep: \(metrics.sleepHours.map { String(format: "%.1f hours", $0) } ?? "N/A")
        - Weight: \(metrics.bodyWeight.map { String(format: "%.1f kg", $0) } ?? "N/A")
        - Resting HR: \(metrics.restingHeartRate.map { String(format: "%.0f bpm", $0) } ?? "N/A")
        - VO2 Max: \(metrics.vo2Max.map { String(format: "%.1f ml/kg/min", $0) } ?? "N/A")
        """
    }
    
    func getRecentWorkoutsSummary() -> String {
        if recentWorkouts.isEmpty {
            return "No recent workouts found"
        }
        
        let workoutSummary = recentWorkouts.prefix(5).map { workout in
            let activityName = workout.type.name
            let duration = Int(workout.duration / 60)
            let calories = Int(workout.calories)
            return "- \(activityName): \(duration) min, \(calories) kcal"
        }.joined(separator: "\n")
        
        return "Recent Workouts (Last 7 days):\n\(workoutSummary)"
    }
}

// MARK: - HKWorkoutActivityType Extension
extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .walking: return "Walking"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining: return "Strength Training"
        case .basketball: return "Basketball"
        case .soccer: return "Soccer"
        case .tennis: return "Tennis"
        case .hiking: return "Hiking"
        default: return "Workout"
        }
    }
}
