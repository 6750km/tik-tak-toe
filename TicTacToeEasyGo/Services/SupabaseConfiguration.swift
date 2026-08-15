import Foundation
import Supabase

enum SupabaseConfiguration {
    static let redirectURL = URL(string: "tictactoeeasygo://auth-callback")!
    static let confirmationPageURL = URL(string: "https://6750km.github.io/tik-tak-toe/auth-callback.html")!
    static let passwordRecoveryPageURL = URL(string: "https://6750km.github.io/tik-tak-toe/password-recovery.html")!

    static var client: SupabaseClient? {
        guard
            let rawURL = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String,
            let key = Bundle.main.object(forInfoDictionaryKey: "SupabasePublishableKey") as? String,
            !rawURL.isEmpty,
            !key.isEmpty,
            !rawURL.contains("SUPABASE_HOST"),
            !key.contains("SUPABASE_PUBLISHABLE_KEY"),
            let url = URL(string: rawURL)
        else { return nil }

        return SupabaseClient(
            supabaseURL: url,
            supabaseKey: key,
            options: .init(
                auth: .init(
                    storage: AuthClient.Configuration.defaultLocalStorage,
                    redirectToURL: confirmationPageURL,
                    flowType: .pkce
                )
            )
        )
    }
}
