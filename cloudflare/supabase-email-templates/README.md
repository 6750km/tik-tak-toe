# Supabase authentication email branding

In Supabase Dashboard open **Authentication → Email Templates → Confirm signup**.

- Subject: `Confirm your Tic Tac Toe Easy Go account`
- Body: paste the complete contents of `confirmation.html`.

The `{{ .ConfirmationURL }}` variable must remain unchanged because Supabase replaces it
with the one-time verification link.

In **Authentication → URL Configuration**, add this redirect URL:

`https://6750km.github.io/tik-tak-toe/auth-callback.html`

Keep `tictactoeeasygo://auth-callback` as an allowed redirect as well. The HTTPS page
shows a clear success or error message and then forwards the authentication response to
the installed iOS app.

For **Reset password**:

- Subject: `Reset your Tic Tac Toe Easy Go password`
- Body: paste the complete contents of `password-reset.html`.
- Set the email link/OTP expiry to `7200` seconds (2 hours).
- Keep `https://6750km.github.io/tik-tak-toe/password-recovery.html` in the allowed redirect URLs.
