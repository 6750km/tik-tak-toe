import Foundation

enum ReleaseFeatures {
    // The first App Store release is completely free. Keep the monetization
    // implementation dormant so it can be enabled deliberately in a later release.
    static let monetizationEnabled = false
}

@MainActor
final class GameQuotaStore: ObservableObject {
    static let guestAllowance = 10

    @Published private(set) var gamesPlayed: Int
    @Published var hasUnlimitedAccess = false

    private let defaults: UserDefaults
    private let gamesPlayedKey = "guestGamesPlayed"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        gamesPlayed = defaults.integer(forKey: gamesPlayedKey)
    }

    var gamesRemaining: Int {
        hasUnlimitedAccess ? .max : max(0, Self.guestAllowance - gamesPlayed)
    }

    var canStartGame: Bool { hasUnlimitedAccess || gamesRemaining > 0 }

    func recordCompletedGame() {
        guard !hasUnlimitedAccess else { return }
        gamesPlayed += 1
        defaults.set(gamesPlayed, forKey: gamesPlayedKey)
    }

    func markGuestGamesTransferred() {
        guard !hasUnlimitedAccess else { return }
        gamesPlayed = Self.guestAllowance
        defaults.set(gamesPlayed, forKey: gamesPlayedKey)
    }
}
