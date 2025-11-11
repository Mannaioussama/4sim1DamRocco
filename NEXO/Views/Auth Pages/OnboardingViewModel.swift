//
//  OnboardingViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI
import Combine

struct OnboardingScreenData {
    let title: String
    let subtitle: String
    let imageURL: URL
    let iconName: String
    let accentColor: Color
}

@MainActor
class OnboardingViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentStep: Int = 0
    
    // MARK: - Properties
    let steps: [OnboardingScreenData]
    private let onComplete: () -> Void
    
    // MARK: - Computed Properties
    var isLastStep: Bool {
        currentStep >= steps.count - 1
    }
    
    var currentStepData: OnboardingScreenData {
        steps[currentStep]
    }
    
    var buttonTitle: String {
        isLastStep ? "Get Started" : "Next"
    }
    
    var buttonIcon: String {
        isLastStep ? "arrow.right.circle.fill" : "arrow.right"
    }
    
    // MARK: - Initialization
    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        self.steps = [
            OnboardingScreenData(
                title: "Welcome to NEXO",
                subtitle: "Connect with people who love sports as much as you do",
                imageURL: URL(string: "https://images.unsplash.com/photo-1760879946121-893199733851?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080")!,
                iconName: "waveform.path.ecg",
                accentColor: Color(hex: "8B5CF6")
            ),
            OnboardingScreenData(
                title: "Find Your Sport Partners",
                subtitle: "Discover nearby activities and join sessions with like-minded people",
                imageURL: URL(string: "https://images.unsplash.com/photo-1758684051112-3df152ce3256?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080")!,
                iconName: "person.3.fill",
                accentColor: Color(hex: "EC4899")
            ),
            OnboardingScreenData(
                title: "Stay Active Together",
                subtitle: "Create your own activities or join existing ones near you",
                imageURL: URL(string: "https://images.unsplash.com/photo-1760879946121-893199733851?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080")!,
                iconName: "mappin.circle.fill",
                accentColor: Color(hex: "10B981")
            )
        ]
    }
    
    // MARK: - Methods
    func nextStep() {
        if currentStep < steps.count - 1 {
            currentStep += 1
        } else {
            complete()
        }
    }
    
    func skip() {
        complete()
    }
    
    private func complete() {
        onComplete()
    }
}
