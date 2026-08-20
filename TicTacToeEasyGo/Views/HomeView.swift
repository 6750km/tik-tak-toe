import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var quota: GameQuotaStore
    @EnvironmentObject private var auth: AuthStore
    @Environment(\.colorScheme) private var colorScheme
    let language: AppLanguage
    @Binding var languageCode: String
    @Binding var themePreference: String
    @State private var selectedMode: GameMode?
    @State private var showingPaywall = false
    @State private var showingAccount = false
    @State private var isCheckingGameAccess = false

    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 58))
                    .foregroundStyle(.indigo)
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "circle")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.mint)
                            .background(.background, in: Circle())
                    }
                Text(copy.text(.appName))
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text(copy.text(.chooseMode))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 14) {
                modeButton(.beginner, title: copy.text(.beginner), icon: "face.smiling")
                modeButton(.professional, title: copy.text(.professional), icon: "brain.head.profile")
                modeButton(
                    .twoPlayers,
                    title: copy.text(.twoPlayers),
                    icon: "person.2.fill",
                    locked: ReleaseFeatures.monetizationEnabled
                )
            }

            Group {
                if auth.isAuthenticated && auth.profile == nil && auth.isProfileLoading {
                    ProgressView()
                } else {
                    Text(remainingGamesText)
                        .foregroundStyle(canStartGame ? Color.secondary : Color.red)
                }
            }
            .font(.subheadline.weight(.semibold))

            Spacer()

            Picker(copy.text(.language), selection: $languageCode) {
                ForEach(AppLanguage.allCases) { item in
                    Text(item.label).tag(item.rawValue)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(24)
        .navigationDestination(item: $selectedMode) { mode in
            GameView(mode: mode, language: language, themePreference: $themePreference)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    toggleTheme()
                } label: {
                    Image(systemName: colorScheme == .dark ? "sun.max.fill" : "moon.fill")
                }
                .accessibilityLabel(copy.text(colorScheme == .dark ? .lightTheme : .darkTheme))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAccount = true } label: {
                    accountButtonImage
                }
                .accessibilityLabel(copy.text(.account))
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(language: language)
        }
        .sheet(isPresented: $showingAccount) {
            AccountView(language: language)
        }
        .onChange(of: auth.isPasswordRecovery, initial: true) { _, isRecovering in
            if isRecovering { showingAccount = true }
        }
        .onChange(of: showingAccount) { _, isShowing in
            guard !isShowing, auth.isAuthenticated else { return }
            Task { await auth.loadProfile() }
        }
        .task(id: auth.user?.id) {
            guard auth.isAuthenticated else { return }
            await auth.loadProfile()
        }
    }

    @ViewBuilder private var accountButtonImage: some View {
        if auth.isAuthenticated, let url = auth.avatarURL {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                }
            }
            .frame(width: 28, height: 28)
            .clipShape(Circle())
        } else {
            Image(systemName: auth.isAuthenticated ? "person.crop.circle.fill" : "person.crop.circle")
        }
    }

    private func toggleTheme() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            themePreference = colorScheme == .dark ? "light" : "dark"
        }
    }

    private func modeButton(_ mode: GameMode, title: String, icon: String, locked: Bool = false) -> some View {
        Button {
            if !ReleaseFeatures.monetizationEnabled {
                selectedMode = mode
            } else if locked {
                showingPaywall = true
            } else if auth.isAuthenticated {
                isCheckingGameAccess = true
                Task {
                    let refreshed = await auth.loadProfile()
                    if refreshed {
                        if auth.bonusGamesRemaining > 0 {
                            selectedMode = mode
                        } else {
                            showingPaywall = true
                        }
                    }
                    isCheckingGameAccess = false
                }
            } else if quota.canStartGame {
                selectedMode = mode
            } else {
                showingPaywall = true
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .frame(width: 26)
                Text(title)
                    .font(.headline)
                Spacer()
                if locked {
                    Text(copy.text(.locked))
                        .font(.caption.bold())
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(.indigo.opacity(0.12), in: Capsule())
                }
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .disabled(isCheckingGameAccess)
    }

    private var canStartGame: Bool {
        guard ReleaseFeatures.monetizationEnabled else { return true }
        return auth.isAuthenticated ? auth.bonusGamesRemaining > 0 : quota.canStartGame
    }

    private var remainingGamesText: String {
        guard ReleaseFeatures.monetizationEnabled else { return copy.text(.unlimited) }
        if quota.hasUnlimitedAccess { return copy.text(.unlimited) }
        return copy.gamesRemaining(auth.isAuthenticated ? auth.bonusGamesRemaining : quota.gamesRemaining)
    }
}
