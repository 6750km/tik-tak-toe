import PhotosUI
import SwiftUI
import UIKit

struct AccountView: View {
    @EnvironmentObject private var auth: AuthStore
    @Environment(\.dismiss) private var dismiss
    let language: AppLanguage

    var body: some View {
        NavigationStack {
            Group {
                if !auth.isConfigured {
                    ContentUnavailableView(
                        copy.text(.accountSetupNeeded),
                        systemImage: "externaldrive.badge.exclamationmark",
                        description: Text(copy.text(.accountSetupBody))
                    )
                } else if auth.isPasswordRecovery {
                    NewPasswordView(language: language)
                } else if auth.isAuthenticated {
                    ProfileView(language: language)
                } else {
                    AuthView(language: language)
                }
            }
            .navigationTitle(copy.text(.account))
            .toolbar {
                if !auth.isPasswordRecovery {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(copy.text(.done)) { dismiss() }
                    }
                }
            }
        }
    }

    private var copy: AppCopy { AppCopy(language: language) }
}

private struct AuthView: View {
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var quota: GameQuotaStore
    @Environment(\.dismiss) private var dismiss
    let language: AppLanguage
    @State private var isCreatingAccount = false
    @State private var showingReset = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        Form {
            Picker("", selection: $isCreatingAccount) {
                Text(copy.text(.signIn)).tag(false)
                Text(copy.text(.createAccount)).tag(true)
            }
            .pickerStyle(.segmented)

            if isCreatingAccount {
                TextField(copy.text(.name), text: $name)
                    .textContentType(.name)
            }
            TextField(copy.text(.email), text: $email)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
            SecureField(copy.text(.password), text: $password)
                .textContentType(isCreatingAccount ? .newPassword : .password)
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Button {
                Task {
                    if isCreatingAccount {
                        await auth.signUp(name: name, email: email, password: password)
                    } else {
                        guard await auth.signIn(email: email, password: password) else { return }
                        if ReleaseFeatures.monetizationEnabled,
                           await auth.claimWelcomeGames(guestGamesRemaining: quota.gamesRemaining) {
                            quota.markGuestGamesTransferred()
                        }
                        guard await auth.loadProfile() else { return }
                        dismiss()
                    }
                }
            } label: {
                Text(isCreatingAccount ? copy.text(.createAccount) : copy.text(.signIn))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(auth.isLoading || email.isEmpty || password.count < 6 || (isCreatingAccount && name.isEmpty))

            if auth.isLoading { ProgressView() }
            messageViews

            Button(copy.text(.forgotPassword)) { showingReset = true }
                .font(.footnote)
        }
        .sheet(isPresented: $showingReset) {
            PasswordResetRequestView(language: language, initialEmail: email)
        }
        .onChange(of: auth.isPasswordRecovery) { _, isRecovering in
            if isRecovering { showingReset = false }
        }
    }

    @ViewBuilder private var messageViews: some View {
        if let notice = auth.noticeMessage { Text(notice).foregroundStyle(.green) }
        if let error = auth.errorMessage { Text(error).foregroundStyle(.red) }
    }
}

private struct PasswordResetRequestView: View {
    @EnvironmentObject private var auth: AuthStore
    @Environment(\.dismiss) private var dismiss
    let language: AppLanguage
    @State private var email: String

    init(language: AppLanguage, initialEmail: String) {
        self.language = language
        _email = State(initialValue: initialEmail)
    }

    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        NavigationStack {
            Form {
                TextField(copy.text(.email), text: $email)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                Button(copy.text(.sendResetLink)) {
                    Task { await auth.sendPasswordReset(email: email) }
                }
                .disabled(email.isEmpty || auth.isLoading)
                if let notice = auth.noticeMessage { Text(notice).foregroundStyle(.green) }
                if let error = auth.errorMessage { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle(copy.text(.resetPassword))
            .toolbar { Button(copy.text(.done)) { dismiss() } }
        }
        .onChange(of: auth.isPasswordRecovery) { _, isRecovering in
            if isRecovering { dismiss() }
        }
    }
}

private struct NewPasswordView: View {
    @EnvironmentObject private var auth: AuthStore
    let language: AppLanguage
    @State private var password = ""

    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        Form {
            if auth.isRecoverySessionReady {
                Section {
                    SecureField(copy.text(.newPassword), text: $password)
                        .textContentType(.newPassword)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button(copy.text(.savePassword)) {
                        Task { await auth.updatePassword(password) }
                    }
                    .disabled(password.count < 8 || auth.isLoading)
                } footer: {
                    Text(copy.text(.passwordRequirements))
                }
            } else if auth.errorMessage == nil {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                        Text(copy.text(.preparingPasswordReset))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
            if let error = auth.errorMessage { Text(error).foregroundStyle(.red) }
        }
        .navigationTitle(copy.text(.resetPassword))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(copy.text(.cancel)) { auth.cancelPasswordRecovery() }
            }
        }
    }
}

private struct ProfileView: View {
    @EnvironmentObject private var auth: AuthStore
    let language: AppLanguage
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var cropSelection: AvatarCropSelection?
    @State private var photoSelectionError: String?
    @State private var showingDeleteConfirmation = false

    private let maxSourcePhotoBytes = 10 * 1024 * 1024

    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        Form {
            Section(copy.text(.avatar)) {
                HStack {
                    Spacer()
                    avatarView
                    Spacer()
                }
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label(copy.text(.choosePhoto), systemImage: "photo.on.rectangle")
                }
            }
            Section(copy.text(.profile)) {
                LabeledContent(copy.text(.name), value: auth.displayName)
                LabeledContent(copy.text(.email), value: auth.user?.email ?? "")
                if ReleaseFeatures.monetizationEnabled {
                    LabeledContent(copy.text(.bonusGames), value: "\(auth.bonusGamesRemaining)")
                }
            }
            Button(copy.text(.signOut), role: .destructive) {
                Task { await auth.signOut() }
            }
            Section {
                Link(copy.text(.support), destination: URL(string: "https://kiki-apps.uk/tic-tac-toe-easy-go/support")!)
                Link(copy.text(.privacyPolicy), destination: URL(string: "https://kiki-apps.uk/tic-tac-toe-easy-go/privacy")!)
            }
            Section {
                Button(copy.text(.deleteAccount), role: .destructive) {
                    showingDeleteConfirmation = true
                }
                .disabled(auth.isLoading)
            }
            if let error = auth.errorMessage { Text(error).foregroundStyle(.red) }
            if let photoSelectionError { Text(photoSelectionError).foregroundStyle(.red) }
            if let notice = auth.noticeMessage { Text(notice).foregroundStyle(.green) }
        }
        .onChange(of: selectedPhoto) { _, newItem in
            guard let newItem else { return }
            Task {
                photoSelectionError = nil
                guard let data = try? await newItem.loadTransferable(type: Data.self) else {
                    photoSelectionError = copy.text(.photoLoadFailed)
                    return
                }
                guard data.count <= maxSourcePhotoBytes else {
                    photoSelectionError = copy.text(.photoTooLarge)
                    selectedPhoto = nil
                    return
                }
                guard let image = UIImage(data: data) else {
                    photoSelectionError = copy.text(.photoLoadFailed)
                    return
                }
                cropSelection = AvatarCropSelection(image: image)
            }
        }
        .fullScreenCover(item: $cropSelection) { selection in
            AvatarCropView(image: selection.image, language: language) { data in
                let error = await auth.uploadAvatar(data)
                if error == nil { selectedPhoto = nil }
                return error
            }
        }
        .confirmationDialog(
            copy.text(.deleteAccountTitle),
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(copy.text(.deleteAccountConfirm), role: .destructive) {
                Task {
                    if !(await auth.deleteAccount()) {
                        photoSelectionError = copy.text(.accountDeletionFailed)
                    }
                }
            }
            Button(copy.text(.cancel), role: .cancel) {}
        } message: {
            Text(copy.text(.deleteAccountMessage))
        }
    }

    @ViewBuilder private var avatarView: some View {
        if let url = auth.avatarURL {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else if phase.error != nil {
                    avatarPlaceholder
                } else {
                    ProgressView()
                }
            }
            .frame(width: 104, height: 104)
            .clipShape(Circle())
        } else {
            avatarPlaceholder
        }
    }

    private var avatarPlaceholder: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.indigo.opacity(0.75))
            .frame(width: 104, height: 104)
    }
}

private struct AvatarCropSelection: Identifiable {
    let id = UUID()
    let image: UIImage
}
