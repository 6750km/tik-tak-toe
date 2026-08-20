import Foundation
import Supabase

struct UserProfile: Decodable, Sendable {
    let id: UUID
    let fullName: String?
    let bonusGamesRemaining: Int
    let gamesCompleted: Int
    let avatarPath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case bonusGamesRemaining = "bonus_games_remaining"
        case gamesCompleted = "games_completed"
        case avatarPath = "avatar_path"
    }
}

enum AvatarUploadIssue: Sendable {
    case notSignedIn
    case storagePermissionDenied
    case fileTooLarge
    case storageUploadFailed
    case profileUpdateFailed
}

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var user: User?
    @Published private(set) var profile: UserProfile?
    @Published private(set) var isLoading = false
    @Published private(set) var isProfileLoading = false
    @Published var errorMessage: String?
    @Published var noticeMessage: String?
    @Published var isPasswordRecovery = false
    @Published private(set) var isRecoverySessionReady = false

    let client: SupabaseClient?
    private var authTask: Task<Void, Never>?
    private var didRecordAppOpen = false

    init(client: SupabaseClient? = SupabaseConfiguration.client) {
        self.client = client
        guard let client else { return }

        authTask = Task { [weak self] in
            for await (event, session) in client.auth.authStateChanges {
                guard let self else { return }
                user = session?.user
                if event == .passwordRecovery { isPasswordRecovery = true }
                if session != nil {
                    await loadProfile()
                    await recordAppOpenIfNeeded()
                } else {
                    profile = nil
                }
            }
        }
    }

    deinit { authTask?.cancel() }

    var isConfigured: Bool { client != nil }
    var isAuthenticated: Bool { user != nil }
    var displayName: String {
        profile?.fullName
            ?? user?.userMetadata["full_name"]?.stringValue
            ?? user?.email
            ?? ""
    }
    var bonusGamesRemaining: Int { profile?.bonusGamesRemaining ?? 0 }
    var avatarURL: URL? {
        guard let client, let path = profile?.avatarPath else { return nil }
        return try? client.storage.from("avatars").getPublicURL(path: path)
    }

    func signUp(name: String, email: String, password: String) async {
        guard let client else { return configurationError() }
        await perform {
            let response = try await client.auth.signUp(
                email: email,
                password: password,
                data: ["full_name": .string(name)],
                redirectTo: SupabaseConfiguration.confirmationPageURL
            )
            if response.session == nil {
                noticeMessage = "Check your email to confirm the account."
            }
        }
    }

    @discardableResult
    func signIn(email: String, password: String) async -> Bool {
        guard let client else {
            configurationError()
            return false
        }
        isLoading = true
        errorMessage = nil
        noticeMessage = nil
        defer { isLoading = false }
        do {
            let signedInSession = try await client.auth.signIn(email: email, password: password)
            let persistedSession = try await client.auth.session
            guard persistedSession.user.id == signedInSession.user.id else {
                errorMessage = "The signed-in session could not be restored. Please try again."
                return false
            }
            user = persistedSession.user
            return await loadProfile()
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func signOut() async {
        guard let client else { return }
        await perform { try await client.auth.signOut() }
    }

    @discardableResult
    func deleteAccount() async -> Bool {
        guard let client else {
            configurationError()
            return false
        }
        isLoading = true
        errorMessage = nil
        noticeMessage = nil
        defer { isLoading = false }

        do {
            let session = try await client.auth.session
            let userFolder = session.user.id.uuidString.lowercased()
            let files = try await client.storage.from("avatars").list(path: userFolder)
            let paths = files.map { "\(userFolder)/\($0.name)" }
            if !paths.isEmpty {
                try await client.storage.from("avatars").remove(paths: paths)
            }

            try await client.rpc("delete_account").execute()
            try await client.auth.signOut(scope: .local)
            noticeMessage = "Your account and data were deleted."
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func sendPasswordReset(email: String) async {
        guard let client else { return configurationError() }
        await perform {
            try await client.auth.resetPasswordForEmail(
                email,
                redirectTo: SupabaseConfiguration.passwordRecoveryPageURL
            )
            noticeMessage = "Check your email for the password reset link."
        }
    }

    func updatePassword(_ password: String) async {
        guard let client else { return configurationError() }
        await perform {
            _ = try await client.auth.update(user: .init(password: password))
            isPasswordRecovery = false
            isRecoverySessionReady = false
            noticeMessage = "Password updated."
        }
    }

    func handle(url: URL) {
        guard let client else { return }
        let isRecovery = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .contains(where: { $0.name == "flow" && $0.value == "recovery" }) == true

        if isRecovery {
            isPasswordRecovery = true
            isRecoverySessionReady = false
            errorMessage = nil
        }

        Task {
            do {
                _ = try await client.auth.session(from: url)
                if isRecovery { isRecoverySessionReady = true }
            } catch {
                errorMessage = isRecovery
                    ? "This reset link is invalid or expired. Request a new link and open it on this device."
                    : error.localizedDescription
            }
        }
    }

    func cancelPasswordRecovery() {
        isPasswordRecovery = false
        isRecoverySessionReady = false
        errorMessage = nil
    }

    @discardableResult
    func loadProfile() async -> Bool {
        guard let client, let displayedUser = user else { return false }
        isProfileLoading = true
        defer { isProfileLoading = false }
        do {
            // An auth event can publish the user just before the access token is ready for
            // PostgREST. Resolve (and refresh, when necessary) the session before every
            // protected profile read so the request cannot accidentally run as `anon`.
            let session = try await client.auth.session
            guard session.user.id == displayedUser.id else {
                errorMessage = "Your session changed. Sign in again."
                return false
            }

            let loaded: UserProfile = try await client
                .from("profiles")
                .select()
                .eq("id", value: displayedUser.id)
                .single()
                .execute()
                .value
            guard user?.id == displayedUser.id else { return false }
            profile = loaded
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func consumeBonusGame() async {
        guard let client, user != nil else { return }
        do {
            let remaining: Int = try await client
                .rpc("consume_bonus_game")
                .execute()
                .value
            await loadProfile()
            if remaining == 0 { noticeMessage = "Registration bonus games used." }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func claimWelcomeGames(guestGamesRemaining: Int) async -> Bool {
        guard let client, user != nil else { return false }
        do {
            let _: Int = try await client
                .rpc(
                    "claim_welcome_games",
                    params: ["p_guest_remaining": max(0, min(guestGamesRemaining, 10))]
                )
                .execute()
                .value
            await loadProfile()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func uploadAvatar(_ data: Data) async -> AvatarUploadIssue? {
        guard let client, let displayedUser = user else {
            configurationError()
            return .notSignedIn
        }
        isLoading = true
        errorMessage = nil
        noticeMessage = nil
        defer { isLoading = false }

        // `user` reflects the last auth event and can briefly remain populated after an
        // expired or failed recovery session. Storage must receive a current access token.
        // Resolving `auth.session` refreshes that token when possible and prevents an
        // anonymous upload from being misreported as an RLS configuration problem.
        let session: Session
        do {
            session = try await client.auth.session
            guard session.user.id == displayedUser.id else {
                errorMessage = "Your session changed. Sign in again before uploading a photo."
                return .notSignedIn
            }
        } catch {
            // A failed protected action must not mutate authentication state. Only the
            // auth-state stream (or an explicit sign out) is allowed to clear the user.
            errorMessage = "Your session needs to be refreshed. Sign in again before uploading a photo."
            return .notSignedIn
        }

        do {
            let previousPath = profile?.avatarPath
            // Storage RLS compares the first folder with auth.uid()::text, which is lowercase.
            let userFolder = session.user.id.uuidString.lowercased()
            let path = "\(userFolder)/avatar-\(UUID().uuidString.lowercased()).jpg"

            do {
                try await client.storage
                    .from("avatars")
                    .upload(
                        path,
                        data: data,
                        options: .init(cacheControl: "31536000", contentType: "image/jpeg")
                    )
            } catch {
                let issue = avatarStorageIssue(for: error)
                errorMessage = error.localizedDescription
                return issue
            }

            do {
                let _: String = try await client
                    .rpc("set_avatar_path", params: ["p_path": path])
                    .execute()
                    .value
            } catch {
                // The database link was not saved, so avoid leaving an orphaned object.
                _ = try? await client.storage.from("avatars").remove(paths: [path])
                errorMessage = error.localizedDescription
                return .profileUpdateFailed
            }

            if let previousPath, previousPath != path {
                _ = try? await client.storage.from("avatars").remove(paths: [previousPath])
            }
            await loadProfile()
            guard profile?.avatarPath == path else {
                return .profileUpdateFailed
            }
            noticeMessage = "Profile photo updated."
            return nil
        }
    }

    private func avatarStorageIssue(for error: Error) -> AvatarUploadIssue {
        let message = error.localizedDescription.lowercased()
        if message.contains("row-level security") || message.contains("unauthorized") {
            return .storagePermissionDenied
        }
        if message.contains("too large") || message.contains("413") || message.contains("maximum") {
            return .fileTooLarge
        }
        return .storageUploadFailed
    }

    private func recordAppOpenIfNeeded() async {
        guard let client, user != nil, !didRecordAppOpen else { return }
        didRecordAppOpen = true
        do {
            try await client.rpc("record_app_open").execute()
            await loadProfile()
        } catch {
            didRecordAppOpen = false
            // Usage analytics must never replace an otherwise healthy account screen
            // with a technical database error. A later app activation retries it.
        }
    }

    private func perform(_ operation: () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        noticeMessage = nil
        defer { isLoading = false }
        do {
            try await operation()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func configurationError() {
        errorMessage = "Supabase is not configured yet."
    }
}
