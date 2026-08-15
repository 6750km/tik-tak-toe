import SwiftUI

struct RootView: View {
    @EnvironmentObject private var quota: GameQuotaStore
    @EnvironmentObject private var auth: AuthStore
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("selectedLanguage") private var languageCode = AppLanguage.english.rawValue
    @AppStorage("themePreference") private var themePreference = "system"

    private var language: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .english
    }

    var body: some View {
        NavigationStack {
            HomeView(
                language: language,
                languageCode: $languageCode,
                themePreference: $themePreference
            )
        }
        .tint(.indigo)
        .preferredColorScheme(preferredColorScheme)
        .task(id: auth.user?.id) {
            guard auth.isAuthenticated else { return }
            if await auth.claimWelcomeGames(guestGamesRemaining: quota.gamesRemaining) {
                quota.markGuestGamesTransferred()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, auth.isAuthenticated else { return }
            Task { await auth.loadProfile() }
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch themePreference {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }
}
