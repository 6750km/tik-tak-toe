# Kiki Apps website

This directory is the restorable source of the public website at `kiki-apps.uk`.

## Content locations

- `index.html` — home page copy.
- `privacy.html` — privacy policy copy.
- `support.html` — support guide and contact-form copy.
- `functions/support/message/[id].js` — protected support-message page copy.
- `functions/api/support.js` — form validation, Turnstile verification, D1 storage, and notification request.
- `styles.css` and `support.css` — page presentation.
- `schema.sql` — complete D1 schema for a fresh installation.
- `migrate-notifications.sql` — migration used to add notification-link fields to the existing database.
- `wrangler.toml` — Pages, D1, and email-notifier service bindings.

The email subject and plain-text/HTML notification templates are stored in
`../email-worker/src/index.js`.

## Cloudflare resources

- Pages project: `kiki-apps`
- D1 database: `kiki-support`
- Notification Worker: `kiki-support-notifier`
- Turnstile widget sitekey: `0x4AAAAAAEQ_xD0Vrnkml5gH`
- Notification destination: `6750km@gmail.com`

Secrets are intentionally not committed. `TURNSTILE_SECRET_KEY` remains an
encrypted Pages secret in Cloudflare.

## Restore and deploy

Deploy the notification Worker first:

```sh
cd cloudflare/email-worker
npx wrangler deploy
```

Then deploy Pages:

```sh
cd ../site
npx wrangler pages deploy . --project-name kiki-apps --branch main
```

For a new D1 database, apply `schema.sql`. For an existing pre-notification
database, apply `migrate-notifications.sql` once.

The Turnstile secret can be restored without printing it:

```sh
npx wrangler turnstile widget get 0x4AAAAAAEQ_xD0Vrnkml5gH --json \
  | jq -r .secret \
  | npx wrangler pages secret put TURNSTILE_SECRET_KEY --project-name kiki-apps
```
