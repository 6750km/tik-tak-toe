import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case spanish = "es"
    case russian = "ru"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .english: "English"
        case .spanish: "Español"
        case .russian: "Русский"
        }
    }
}

enum CopyKey: String {
    case appName, chooseMode, beginner, professional, twoPlayers, locked
    case gamesRemaining, unlimited, play, yourTurn, computerTurn, playerTurn
    case xWon, oWon, draw, playAgain, back, limitReached, unlockTitle
    case unlockBody, purchaseBody, later, language, comingSoon
    case account, done, signIn, createAccount, name, email, password
    case forgotPassword, resetPassword, sendResetLink, newPassword, savePassword
    case profile, bonusGames, signOut, accountSetupNeeded, accountSetupBody
    case avatar, choosePhoto, cropPhoto, moveAndScalePhoto, usePhoto, cancel
    case darkTheme, lightTheme
    case preparingPasswordReset, passwordRequirements, photoTooLarge, photoLoadFailed
    case avatarNotSignedIn, avatarStoragePermissionDenied, avatarOutputTooLarge
    case avatarStorageUploadFailed, avatarProfileUpdateFailed
}

struct AppCopy {
    let language: AppLanguage

    func text(_ key: CopyKey) -> String {
        Self.values[language]?[key] ?? Self.values[.english]?[key] ?? key.rawValue
    }

    func gamesRemaining(_ count: Int) -> String {
        String(format: text(.gamesRemaining), count)
    }

    private static let values: [AppLanguage: [CopyKey: String]] = [
        .english: [
            .appName: "Tic Tac Toe Easy Go", .chooseMode: "Choose a game", .beginner: "Beginner",
            .professional: "Professional", .twoPlayers: "Two players", .locked: "Premium",
            .gamesRemaining: "%d free games left", .unlimited: "Unlimited games", .play: "Play",
            .yourTurn: "Your turn", .computerTurn: "Computer is thinking…", .playerTurn: "%@'s turn",
            .xWon: "X wins!", .oWon: "O wins!", .draw: "It's a draw", .playAgain: "Play again",
            .back: "Back", .limitReached: "Free games used", .unlockTitle: "Keep playing",
            .unlockBody: "Create an account or choose a plan to unlock more games.", .later: "Not now",
            .purchaseBody: "Your free games are used. Choose a plan to keep playing.",
            .language: "Language", .comingSoon: "Purchases will be enabled before release.",
            .account: "Account", .done: "Done", .signIn: "Sign in", .createAccount: "Create account",
            .name: "Name", .email: "Email", .password: "Password", .forgotPassword: "Forgot password?",
            .resetPassword: "Reset password", .sendResetLink: "Send reset link", .newPassword: "New password",
            .savePassword: "Save password", .profile: "Profile", .bonusGames: "Bonus games",
            .signOut: "Sign out", .accountSetupNeeded: "Account setup pending",
            .accountSetupBody: "Add the Supabase project URL and publishable key to Config.xcconfig.",
            .avatar: "Profile photo", .choosePhoto: "Choose a photo", .cropPhoto: "Crop photo",
            .moveAndScalePhoto: "Move and zoom the photo inside the square.", .usePhoto: "Use photo",
            .cancel: "Cancel", .darkTheme: "Dark theme", .lightTheme: "Light theme",
            .preparingPasswordReset: "Preparing password reset…",
            .passwordRequirements: "Use at least 8 characters.",
            .photoTooLarge: "Choose a photo smaller than 10 MB.",
            .photoLoadFailed: "The selected photo could not be opened. Choose another photo.",
            .avatarNotSignedIn: "The photo was not uploaded because your session has ended. Sign in again and retry.",
            .avatarStoragePermissionDenied: "The photo file was not uploaded: Supabase Storage denied write access for this account.",
            .avatarOutputTooLarge: "The cropped photo is larger than the 2 MB storage limit.",
            .avatarStorageUploadFailed: "The photo file could not be uploaded to Supabase Storage. Check your connection and retry.",
            .avatarProfileUpdateFailed: "The photo file was uploaded, but your profile could not be linked to it. Retry or contact support."
        ],
        .spanish: [
            .appName: "Tic Tac Toe Easy Go", .chooseMode: "Elige una partida", .beginner: "Principiante",
            .professional: "Profesional", .twoPlayers: "Dos jugadores", .locked: "Premium",
            .gamesRemaining: "Quedan %d partidas gratis", .unlimited: "Partidas ilimitadas", .play: "Jugar",
            .yourTurn: "Tu turno", .computerTurn: "El ordenador está pensando…", .playerTurn: "Turno de %@",
            .xWon: "¡Gana X!", .oWon: "¡Gana O!", .draw: "Empate", .playAgain: "Jugar de nuevo",
            .back: "Atrás", .limitReached: "Partidas gratis agotadas", .unlockTitle: "Sigue jugando",
            .unlockBody: "Crea una cuenta o elige un plan para desbloquear más partidas.", .later: "Ahora no",
            .purchaseBody: "Has agotado tus partidas gratis. Elige un plan para seguir jugando.",
            .language: "Idioma", .comingSoon: "Las compras se activarán antes del lanzamiento.",
            .account: "Cuenta", .done: "Listo", .signIn: "Iniciar sesión", .createAccount: "Crear cuenta",
            .name: "Nombre", .email: "Correo electrónico", .password: "Contraseña", .forgotPassword: "¿Olvidaste la contraseña?",
            .resetPassword: "Restablecer contraseña", .sendResetLink: "Enviar enlace", .newPassword: "Nueva contraseña",
            .savePassword: "Guardar contraseña", .profile: "Perfil", .bonusGames: "Partidas extra",
            .signOut: "Cerrar sesión", .accountSetupNeeded: "Configuración pendiente",
            .accountSetupBody: "Añade la URL y la clave pública de Supabase a Config.xcconfig.",
            .avatar: "Foto de perfil", .choosePhoto: "Elegir una foto", .cropPhoto: "Recortar foto",
            .moveAndScalePhoto: "Mueve y amplía la foto dentro del cuadrado.", .usePhoto: "Usar foto",
            .cancel: "Cancelar", .darkTheme: "Tema oscuro", .lightTheme: "Tema claro",
            .preparingPasswordReset: "Preparando el cambio de contraseña…",
            .passwordRequirements: "Usa al menos 8 caracteres.",
            .photoTooLarge: "Elige una foto de menos de 10 MB.",
            .photoLoadFailed: "No se ha podido abrir la foto. Elige otra.",
            .avatarNotSignedIn: "La foto no se ha subido porque tu sesión ha caducado. Inicia sesión de nuevo.",
            .avatarStoragePermissionDenied: "La foto no se ha subido: Supabase Storage ha denegado el permiso de escritura de esta cuenta.",
            .avatarOutputTooLarge: "La foto recortada supera el límite de almacenamiento de 2 MB.",
            .avatarStorageUploadFailed: "No se ha podido subir la foto a Supabase Storage. Comprueba la conexión e inténtalo de nuevo.",
            .avatarProfileUpdateFailed: "La foto se ha subido, pero no se ha podido vincular al perfil. Inténtalo de nuevo o contacta con soporte."
        ],
        .russian: [
            .appName: "Tic Tac Toe Easy Go", .chooseMode: "Выберите игру", .beginner: "Новичок",
            .professional: "Профи", .twoPlayers: "Два игрока", .locked: "Премиум",
            .gamesRemaining: "Осталось бесплатных игр: %d", .unlimited: "Игры без ограничений", .play: "Играть",
            .yourTurn: "Ваш ход", .computerTurn: "Компьютер думает…", .playerTurn: "Ход %@",
            .xWon: "Победил X!", .oWon: "Победил O!", .draw: "Ничья", .playAgain: "Играть снова",
            .back: "Назад", .limitReached: "Бесплатные игры закончились", .unlockTitle: "Продолжить игру",
            .unlockBody: "Создайте аккаунт или выберите тариф, чтобы открыть больше игр.", .later: "Не сейчас",
            .purchaseBody: "Бесплатные игры закончились. Выберите тариф, чтобы продолжить играть.",
            .language: "Язык", .comingSoon: "Покупки будут подключены до публикации.",
            .account: "Аккаунт", .done: "Готово", .signIn: "Войти", .createAccount: "Создать аккаунт",
            .name: "Имя", .email: "Email", .password: "Пароль", .forgotPassword: "Забыли пароль?",
            .resetPassword: "Восстановить пароль", .sendResetLink: "Отправить ссылку", .newPassword: "Новый пароль",
            .savePassword: "Сохранить пароль", .profile: "Профиль", .bonusGames: "Бонусные игры",
            .signOut: "Выйти", .accountSetupNeeded: "Нужно настроить аккаунты",
            .accountSetupBody: "Добавьте URL проекта и публичный ключ Supabase в Config.xcconfig.",
            .avatar: "Фото профиля", .choosePhoto: "Выбрать фото", .cropPhoto: "Обрезать фото",
            .moveAndScalePhoto: "Перемещайте и увеличивайте фото внутри квадрата.", .usePhoto: "Использовать фото",
            .cancel: "Отмена", .darkTheme: "Тёмная тема", .lightTheme: "Светлая тема",
            .preparingPasswordReset: "Подготавливаем смену пароля…",
            .passwordRequirements: "Используйте не менее 8 символов.",
            .photoTooLarge: "Выберите фото размером меньше 10 МБ.",
            .photoLoadFailed: "Не удалось открыть выбранное фото. Выберите другое.",
            .avatarNotSignedIn: "Фото не загружено: сессия завершилась. Войдите в аккаунт заново и повторите попытку.",
            .avatarStoragePermissionDenied: "Файл фото не загружен: Supabase Storage запретил запись для этого аккаунта.",
            .avatarOutputTooLarge: "Обрезанное фото превышает лимит хранилища 2 МБ.",
            .avatarStorageUploadFailed: "Не удалось загрузить файл фото в Supabase Storage. Проверьте интернет и повторите попытку.",
            .avatarProfileUpdateFailed: "Файл загружен, но не удалось привязать его к профилю. Повторите попытку или обратитесь в поддержку."
        ]
    ]
}
