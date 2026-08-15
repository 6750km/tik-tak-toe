import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthStore
    let language: AppLanguage

    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "lock.open.fill")
                .font(.system(size: 54))
                .foregroundStyle(.indigo)
            Text(copy.text(.unlockTitle))
                .font(.largeTitle.bold())
            Text(copy.text(auth.isAuthenticated ? .purchaseBody : .unlockBody))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Text(copy.text(.comingSoon))
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
            Button(copy.text(.later)) { dismiss() }
                .buttonStyle(.bordered)
                .controlSize(.large)
        }
        .padding(28)
        .presentationDetents([.medium])
    }
}
