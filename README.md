# Tic Tac Toe Easy Go

The first App Store release is completely free: all game modes are available without game limits or purchases. The dormant monetization flow is controlled by `ReleaseFeatures.monetizationEnabled` and must only be enabled for a later release with configured StoreKit products.

Native iPhone app built with SwiftUI.

## Build

Open `TicTacToeEasyGo.xcodeproj` in Xcode, select an iPhone simulator, and run the `TicTacToeEasyGo` scheme.

Code signing is configured with automatic signing. Select the personal Apple Developer team in the target's **Signing & Capabilities** tab before running on a physical iPhone.

## Supabase setup

1. Create a Supabase project on the Free plan in the closest available EU region.
2. Open **SQL Editor**, paste the contents of
   `supabase/migrations/202608130001_initial.sql`, and run it once.
3. Open **Project Settings → API** (or **Connect**) and copy:
   - the project URL host, for example `abcdefgh.supabase.co`;
   - the publishable key (a legacy `anon` key also works while Supabase offers it).
4. Put those two values in `Config.xcconfig`. Never put the database password or a
   `service_role`/secret key in the iOS project.
5. In **Authentication → URL Configuration**, add this redirect URL:
   `tictactoeeasygo://auth-callback`.

After publishing the bundled GitHub Pages callback, also add:
`https://6750km.github.io/tik-tak-toe/auth-callback.html`.

Run all SQL files from `supabase/migrations` in filename order. Email branding values
and the ready-to-paste confirmation template are in `supabase/email-templates`.

The current MVP supports email/password registration, email confirmation, sign-in,
sign-out, password recovery by email link, a profile, and server-side accounting for
the 10 post-registration bonus games. Apple and Google sign-in are separate follow-up
steps.
