import SwiftUI
import RevenueCat

@main
struct CoReplyApp: App {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var profileStore = RelationshipProfileStore.shared
    @StateObject private var personalityStore = PersonalityStore.shared
    @AppStorage(AppConstants.AppGroup.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    init() {
        configureRevenueCat()
        setupAppearance()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    HomeView()
                        .environmentObject(subscriptionService)
                        .environmentObject(profileStore)
                        .environmentObject(personalityStore)
                } else {
                    OnboardingView()
                        .environmentObject(subscriptionService)
                        .environmentObject(profileStore)
                        .environmentObject(personalityStore)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - RevenueCat

    private func configureRevenueCat() {
        let key = KeychainService.shared.load(key: AppConstants.Keys.revenueCatKey) ?? ""
        guard !key.isEmpty else { return }
        Purchases.logLevel = .error
        Purchases.configure(withAPIKey: key)
        Purchases.shared.attribution.collectDeviceIdentifiers()
    }

    // MARK: - Appearance

    private func setupAppearance() {
        // Navigation bar
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(red: 13/255, green: 13/255, blue: 26/255, alpha: 0.95)
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        navAppearance.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor(red: 139/255, green: 92/255, blue: 246/255, alpha: 1)

        // Tab bar
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(red: 13/255, green: 13/255, blue: 26/255, alpha: 0.97)
        tabAppearance.shadowColor = .clear

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.4)
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.4)]
        itemAppearance.selected.iconColor = UIColor(red: 139/255, green: 92/255, blue: 246/255, alpha: 1)
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(red: 139/255, green: 92/255, blue: 246/255, alpha: 1)]
        tabAppearance.stackedLayoutAppearance = itemAppearance
        tabAppearance.inlineLayoutAppearance = itemAppearance
        tabAppearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        // Table view
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
    }
}
