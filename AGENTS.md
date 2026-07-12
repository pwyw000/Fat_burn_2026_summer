# AGENTS.md

## Cursor Cloud specific instructions

This repo is a small single-package Node.js (ESM) project. Its only runnable code is
`scripts/send-fat-loss-email.mjs`, which emails the day's fat-loss plan via Gmail SMTP.
There is no web server, API, frontend, database, or Docker — nothing long-running to keep up.

### Services / commands
- There are **no lint, test, or build scripts** defined (`package.json` only has `send-email`
  and `send-email:dry`). Do not invent them.
- Dry-run (offline, never sends): `npm run send-email:dry`
- Real send (needs Gmail secrets, sends a real email): `npm run send-email`

### Non-obvious caveats
- The script does **not** load `.env` — there is no dotenv loader. `GMAIL_USER` /
  `GMAIL_APP_PASSWORD` (and optional `EMAIL_TO`) must already be exported in the shell.
  In Cloud Agents these come from configured secrets and are present in the environment.
- Email body source (first match wins): `--file <path>` → `EMAIL_BODY_FILE` → stdin →
  `logs/plans/<YYYY-MM-DD>.md` where the date is **America/New_York** "today" (not UTC).
  With no body source available the script errors out; for a dry-run either pass
  `--file` or create a `logs/plans/<eastern-date>.md` file.
- `logs/plans/*.md` are normally auto-generated per day; treat any you create for testing
  as throwaway demo data and do not commit them.
- Running `npm run send-email` sends a real email to `EMAIL_TO` (default `pwyw000@gmail.com`).
  Use `send-email:dry` unless you specifically intend to deliver mail.
