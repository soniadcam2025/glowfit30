# Legacy webhook deploy (documented, not the primary path)

The production VPS runs a second auto-deploy mechanism next to GitHub Actions:

- `webhook.service` (systemd, user `sprsadmin`) runs [`adnanh/webhook`](https://github.com/adnanh/webhook) on **port 9000** (open in ufw).
- It reads `/var/www/glowfit/webhook.json` — a GitHub `X-Hub-Signature-256` HMAC rule. The real file holds the webhook secret and is **not** in git; `webhook.json.example` here has a placeholder.
- A valid push event runs `/var/www/glowfit/deploy.sh` — preserved here verbatim as `deploy.sh` (it lives untracked at the checkout root on the server).

Files here are copies taken from the VPS on 2026-10-14. Editing them does not change the server.

**Status (2026-10-14):** the service is active, but the server's git reflog shows its `git pull origin main` last ran on **2026-07-26**; every deploy since has been GitHub Actions (`git pull --ff-only`). **Verified 2026-10-14 from the GitHub side:** the repository webhook is still active and GitHub delivers every push to `http://139.84.149.147:9000/hooks/deploy-glowfit` — over **plain HTTP** — and each delivery fails with `500 Error occurred while evaluating hook rules`, so `deploy.sh` never runs. It cannot race GitHub Actions, but every push produces a failed delivery and port 9000 stays publicly open for nothing.

**Recommendation:** keep GitHub Actions as the only deploy path. Retiring this one is a separate, deliberate change: remove the GitHub webhook, `systemctl disable --now webhook`, and close port 9000 (`ufw delete allow 9000/tcp`). Do not recreate it on a replacement server — see `RECOVERY.md` §2.8.
