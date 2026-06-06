import SwiftUI
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: - Step Definitions

    enum Step: Int, CaseIterable {
        case welcome = 0
        case name = 1
        case ageRange = 2
        case language = 3
        case communicationStyle = 4
        case done = 5

        var title: String {
            switch self {
            case .welcome:          return "Welcome"
            case .name:             return "Your Name"
            case .ageRange:         return "Your Age Range"
            case .language:         return "Preferred Language"
            case .communicationStyle: return "Communication Style"
            case .done:             return "All Set!"
            }
        }
    }

    // MARK: - Published Properties

    @Published var currentStep: Int = 0
    @Published var name: String = ""
    @Published var selectedAgeRange: CoUser.AgeRange = .youngAdult
    @Published var selectedLanguage: CoUser.Language = .english
    @Published var selectedCommunicationStyle: CoUser.CommunicationStyle = .casual
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showError: Bool = false

    @AppStorage(AppConstants.AppGroup.hasCompletedOnboarding)
    private var hasCompletedOnboarding: Bool = false

    // MARK: - Computed Properties

    var totalSteps: Int { Step.allCases.count }

    var progress: Double {
        guard totalSteps > 1 else { return 1.0 }
        return Double(currentStep) / Double(totalSteps - 1)
    }

    var canProceed: Bool {
        switch Step(rawValue: currentStep) {
        case .welcome:
            return true
        case .name:
            return name.trimmingCharacters(in: .whitespaces).count >= 2
        case .ageRange:
            return true
        case .language:
            return true
        case .communicationStyle:
            return true
        case .done:
            return true
        case .none:
            return false
        }
    }

    var isLastStep: Bool {
        currentStep == totalSteps - 1
    }

    var isFirstStep: Bool {
        currentStep == 0
    }

    // MARK: - Navigation

    func nextStep() {
        guard canProceed, currentStep < totalSteps - 1 else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentStep += 1
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func previousStep() {
        guard currentStep > 0 else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentStep -= 1
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func skipCurrentStep() {
        guard currentStep < totalSteps - 1 else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentStep += 1
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - Complete Onboarding

    func completeOnboarding() async {
        isLoading = true
        defer { isLoading = false }

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let finalName = trimmedName.isEmpty ? "User" : trimmedName

        // Build CoUser
        let user = CoUser(
            name: finalName,
            ageRange: selectedAgeRange,
            language: selectedLanguage,
            communicationStyle: selectedCommunicationStyle
        )

        // Persist to AppGroupStorage
        AppGroupStorage.shared.saveUser(user)
        AppGroupStorage.shared.set(value: finalName, forKey: AppConstants.AppGroup.userName)
        AppGroupStorage.shared.set(value: selectedLanguage.rawValue, forKey: AppConstants.AppGroup.defaultLanguage)
        AppGroupStorage.shared.set(value: selectedCommunicationStyle.rawValue, forKey: AppConstants.AppGroup.defaultCommunicationStyle)

        // Create anonymous Supabase session
        do {
            try await SupabaseService.shared.signInAnonymously()
        } catch {
            // Anonymous sign-in failure is non-fatal — we proceed anyway
            print("[OnboardingViewModel] Supabase anonymous sign-in failed: \(error.localizedDescription)")
        }

        // Mark onboarding complete
        hasCompletedOnboarding = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - Error Handling

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}
