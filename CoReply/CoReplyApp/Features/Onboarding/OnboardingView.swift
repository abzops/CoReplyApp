import SwiftUI

// MARK: - OnboardingView

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var slideDirection: CGFloat = 1
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [Color(hex: "#0D0D1A"), Color(hex: "#1A0D2E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Ambient glow
            Circle()
                .fill(Color(hex: "#8B5CF6").opacity(0.12))
                .frame(width: 340, height: 340)
                .blur(radius: 80)
                .offset(x: -60, y: -120)

            Circle()
                .fill(Color(hex: "#EC4899").opacity(0.08))
                .frame(width: 280, height: 280)
                .blur(radius: 80)
                .offset(x: 100, y: 200)

            VStack(spacing: 0) {
                // Top Bar
                topBar

                // Step Content
                ZStack {
                    ForEach(0..<viewModel.totalSteps, id: \.self) { index in
                        stepContent(for: index)
                            .offset(x: offsetForStep(index))
                            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: viewModel.currentStep)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Bottom Navigation
                if viewModel.currentStep < viewModel.totalSteps - 1 {
                    bottomNavigation
                        .padding(.bottom, 36)
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text(viewModel.errorMessage ?? "Something went wrong.")
        })
    }

    // MARK: - Top Bar

    private var topBar: some View {
        VStack(spacing: 12) {
            HStack {
                // Skip button
                if viewModel.currentStep > 0 && viewModel.currentStep < viewModel.totalSteps - 1 {
                    Button("Skip") {
                        viewModel.skipCurrentStep()
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.leading, 24)
                } else {
                    Spacer().frame(width: 60)
                }

                Spacer()

                // Step indicator
                Text("\(viewModel.currentStep + 1) of \(viewModel.totalSteps)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.trailing, 24)
            }
            .frame(height: 44)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.white.opacity(0.1))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#8B5CF6"), Color(hex: "#EC4899")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * viewModel.progress, height: 4)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.progress)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 24)
        }
        .padding(.top, 12)
    }

    // MARK: - Step Content Router

    @ViewBuilder
    private func stepContent(for index: Int) -> some View {
        switch index {
        case 0: WelcomeStepView()
        case 1: NameStepView(name: $viewModel.name)
        case 2: AgeRangeStepView(selectedAgeRange: $viewModel.selectedAgeRange)
        case 3: LanguageStepView(selectedLanguage: $viewModel.selectedLanguage)
        case 4: CommunicationStyleStepView(selectedStyle: $viewModel.selectedCommunicationStyle)
        case 5: DoneStepView(name: viewModel.name, isLoading: viewModel.isLoading) {
            Task { await viewModel.completeOnboarding() }
        }
        default: EmptyView()
        }
    }

    // MARK: - Slide Offset

    private func offsetForStep(_ index: Int) -> CGFloat {
        let diff = index - viewModel.currentStep
        return CGFloat(diff) * UIScreen.main.bounds.width
    }

    // MARK: - Bottom Navigation

    private var bottomNavigation: some View {
        HStack(spacing: 16) {
            // Back button
            if !viewModel.isFirstStep {
                Button {
                    viewModel.previousStep()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 100, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }

            // Next/Continue button
            Button {
                viewModel.nextStep()
            } label: {
                HStack(spacing: 6) {
                    Text(viewModel.currentStep == 0 ? "Get Started" : "Continue")
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Group {
                        if viewModel.canProceed {
                            LinearGradient(
                                colors: [Color(hex: "#8B5CF6"), Color(hex: "#6D28D9")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            LinearGradient(
                                colors: [Color.white.opacity(0.1), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: viewModel.canProceed ? Color(hex: "#8B5CF6").opacity(0.4) : .clear, radius: 12, y: 4)
                .animation(.easeInOut(duration: 0.2), value: viewModel.canProceed)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canProceed)
        }
        .padding(.horizontal, 24)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.currentStep)
    }
}

// MARK: - Step 0: Welcome

struct WelcomeStepView: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var glowPulse: Bool = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "#8B5CF6").opacity(glowPulse ? 0.35 : 0.2), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: glowPulse)

                RoundedRectangle(cornerRadius: 30)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#8B5CF6"), Color(hex: "#6D28D9")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 96)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color(hex: "#8B5CF6").opacity(0.5), radius: 20, y: 8)

                Image(systemName: "keyboard.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.white)
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)

            // Title
            VStack(spacing: 12) {
                Text("CoReply AI")
                    .font(.system(size: 36, weight: .bold, design: .default))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(hex: "#C4B5FD")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("AI Replies. Instantly.")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#8B5CF6"), Color(hex: "#EC4899")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Your intelligent keyboard companion\nthat crafts the perfect reply every time.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 4)
            }
            .opacity(textOpacity)

            // Feature pills
            VStack(spacing: 12) {
                featurePill(icon: "bolt.fill", text: "Instant AI-powered replies", color: Color(hex: "#8B5CF6"))
                featurePill(icon: "heart.fill", text: "Personalized to your style", color: Color(hex: "#EC4899"))
                featurePill(icon: "lock.shield.fill", text: "Private & on-device first", color: Color(hex: "#10B981"))
            }
            .opacity(textOpacity)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.1)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                textOpacity = 1.0
            }
            glowPulse = true
        }
    }

    private func featurePill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.15))
                .clipShape(Circle())

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.8))

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Step 1: Name

struct NameStepView: View {
    @Binding var name: String
    @FocusState private var isFocused: Bool
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 8) {
                Text("👋")
                    .font(.system(size: 60))

                Text("What's your name?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("We'll personalize your experience.")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            // Glass text field
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(Color(hex: "#8B5CF6"))
                    .font(.system(size: 16))

                TextField("Your name", text: $name)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .tint(Color(hex: "#8B5CF6"))
                    .focused($isFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isFocused ? Color(hex: "#8B5CF6").opacity(0.7) : Color.white.opacity(0.15),
                                lineWidth: isFocused ? 1.5 : 1
                            )
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            if name.trimmingCharacters(in: .whitespaces).count >= 2 {
                Text("Nice to meet you, \(name.trimmingCharacters(in: .whitespaces))! 🎉")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "#8B5CF6"))
                    .transition(.scale.combined(with: .opacity))
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { isFocused = true }
        }
        .onDisappear { isFocused = false }
    }
}

// MARK: - Step 2: Age Range

struct AgeRangeStepView: View {
    @Binding var selectedAgeRange: CoUser.AgeRange
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 8) {
                Text("🎂")
                    .font(.system(size: 60))
                Text("Your Age Range")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text("We'll tune the tone to match your vibe.")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            VStack(spacing: 12) {
                ForEach(CoUser.AgeRange.allCases, id: \.self) { range in
                    AgeRangeCard(range: range, isSelected: selectedAgeRange == range) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedAgeRange = range
                        }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) { appeared = true }
        }
    }
}

struct AgeRangeCard: View {
    let range: CoUser.AgeRange
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(range.emoji)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 2) {
                    Text(range.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text(range.description)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "#8B5CF6"))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color(hex: "#8B5CF6").opacity(0.15) : Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected ? Color(hex: "#8B5CF6").opacity(0.6) : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
            .shadow(color: isSelected ? Color(hex: "#8B5CF6").opacity(0.2) : .clear, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Step 3: Language

struct LanguageStepView: View {
    @Binding var selectedLanguage: CoUser.Language
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 8) {
                Text("🌐")
                    .font(.system(size: 60))
                Text("Preferred Language")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text("How do you usually text?")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.5))
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            VStack(spacing: 12) {
                ForEach(CoUser.Language.allCases, id: \.self) { lang in
                    LanguageCard(language: lang, isSelected: selectedLanguage == lang) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedLanguage = lang
                        }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) { appeared = true }
        }
    }
}

struct LanguageCard: View {
    let language: CoUser.Language
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(language.flagEmoji)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 2) {
                    Text(language.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text(language.subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "#8B5CF6"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color(hex: "#8B5CF6").opacity(0.15) : Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected ? Color(hex: "#8B5CF6").opacity(0.6) : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
            .shadow(color: isSelected ? Color(hex: "#8B5CF6").opacity(0.2) : .clear, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Step 4: Communication Style

struct CommunicationStyleStepView: View {
    @Binding var selectedStyle: CoUser.CommunicationStyle
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("💬")
                    .font(.system(size: 60))
                Text("Your Style")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text("How do you naturally communicate?")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(CoUser.CommunicationStyle.allCases, id: \.self) { style in
                        CommunicationStyleCard(style: style, isSelected: selectedStyle == style) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedStyle = style
                            }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }
                }
                .padding(.bottom, 8)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) { appeared = true }
        }
    }
}

struct CommunicationStyleCard: View {
    let style: CoUser.CommunicationStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(style.emoji)
                        .font(.system(size: 24))
                    Text(style.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "#8B5CF6"))
                    }
                }

                Text(style.description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)

                // Trait chips
                HStack(spacing: 6) {
                    ForEach(style.traits, id: \.self) { trait in
                        Text(trait)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(isSelected ? Color(hex: "#8B5CF6") : .white.opacity(0.5))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color(hex: "#8B5CF6").opacity(0.15) : Color.white.opacity(0.06))
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color(hex: "#8B5CF6").opacity(0.12) : Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected ? Color(hex: "#8B5CF6").opacity(0.6) : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
            .shadow(color: isSelected ? Color(hex: "#8B5CF6").opacity(0.15) : .clear, radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Step 5: Done

struct DoneStepView: View {
    let name: String
    let isLoading: Bool
    let onGetStarted: () -> Void

    @State private var appeared = false
    @State private var particlesScale: CGFloat = 0
    @State private var ringScale: CGFloat = 0.3
    @State private var ringOpacity: Double = 0
    @State private var checkScale: CGFloat = 0
    @State private var particles: [ParticleDot] = DoneStepView.generateParticles()

    struct ParticleDot: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let color: Color
        let size: CGFloat
        let delay: Double
    }

    static func generateParticles() -> [ParticleDot] {
        let colors: [Color] = [Color(hex: "#8B5CF6"), Color(hex: "#EC4899"), Color(hex: "#10B981"), .white]
        return (0..<30).map { _ in
            ParticleDot(
                x: CGFloat.random(in: -160...160),
                y: CGFloat.random(in: -200...50),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 4...10),
                delay: Double.random(in: 0...0.6)
            )
        }
    }

    var body: some View {
        ZStack {
            // Confetti particles
            ForEach(particles) { dot in
                Circle()
                    .fill(dot.color)
                    .frame(width: dot.size, height: dot.size)
                    .offset(x: dot.x, y: appeared ? dot.y - 60 : 60)
                    .opacity(appeared ? 0 : 1)
                    .animation(
                        .easeOut(duration: 1.2).delay(dot.delay),
                        value: appeared
                    )
            }

            VStack(spacing: 32) {
                Spacer()

                // Success animation
                ZStack {
                    // Outer ring pulse
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color(hex: "#8B5CF6"), Color(hex: "#EC4899")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    // Inner circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#8B5CF6"), Color(hex: "#6D28D9")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: Color(hex: "#8B5CF6").opacity(0.5), radius: 20)

                    Image(systemName: "checkmark")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(checkScale)
                }

                VStack(spacing: 12) {
                    let displayName = name.trimmingCharacters(in: .whitespaces)
                    Text("You're all set\(displayName.isEmpty ? "" : ", \(displayName)")! 🎉")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("CoReply AI is ready to craft\nperfect replies for you.")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                // Keyboard setup instruction card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "keyboard.fill")
                            .foregroundColor(Color(hex: "#8B5CF6"))
                            .font(.system(size: 16))
                        Text("Activate Your Keyboard")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        instructionStep("1", text: "Open Settings → General")
                        instructionStep("2", text: "Tap Keyboard → Keyboards")
                        instructionStep("3", text: "Add New Keyboard → CoReply")
                        instructionStep("4", text: "Enable Full Access")
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                // Get Started Button
                Button(action: onGetStarted) {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.85)
                        } else {
                            Text("Start Using CoReply")
                                .font(.system(size: 17, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#8B5CF6"), Color(hex: "#EC4899")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: Color(hex: "#8B5CF6").opacity(0.45), radius: 14, y: 6)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
                .opacity(appeared ? 1 : 0)

                Spacer()
            }
            .padding(.horizontal, 28)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                ringScale = 1.0
                ringOpacity = 1.0
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.35)) {
                checkScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                appeared = true
            }
        }
    }

    private func instructionStep(_ number: String, text: String) -> some View {
        HStack(spacing: 10) {
            Text(number)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color(hex: "#8B5CF6").opacity(0.4))
                .clipShape(Circle())

            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}
