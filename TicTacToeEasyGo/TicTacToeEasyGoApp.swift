import SwiftUI

@main
struct TicTacToeEasyGoApp: App {
    @StateObject private var quota = GameQuotaStore()
    @StateObject private var auth = AuthStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(quota)
                .environmentObject(auth)
                .onOpenURL { auth.handle(url: $0) }
        }
    }
}
