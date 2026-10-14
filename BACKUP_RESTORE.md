# GlowFit 30 — Database Backup & Restore

How the production database (`glowfit_db`) is backed up, where backups live, how to verify them, and how to restore one. For rebuilding a whole server, see [`RECOVERY.md`](RECOVERY.md).

> **This repository is public.** It holds scripts and the *public* encryption key only. Database dumps, the private key and every password live elsewhere — see "What lives where" below.

## At a glance

| | |
|---|---|
| Schedule | **Every night 21:30 UTC** (03:00 IST), `/etc/cron.d/glowfit-backup` on the VPS |
| What | `pg_dump -Fc` of `glowfit_db`, verified, then OpenPGP-encrypted on the VPS to a public key |
| Off-server copy | Private repo [`soniadcam2025/glowfit30-backups`](https://github.com/soniadcam2025/glowfit30-backups), one tag per night: `nightly/<UTC stamp>` |
| Upload proof | After every push the VPS clones the tag back and compares every file byte-for-byte + sha256 |
| Retention | VPS: 14 days. GitHub: every nightly for 30 days, plus the first nightly of each month for 12 months, never fewer than 7 |
| Alarm | Daily GitHub Actions job in the backups repo (01:30 UTC) fails — and GitHub emails the owner — if the newest backup is missing, older than 26 h, unencrypted or fails its checksum |
| Logs | `/var/log/glowfit-backup.log` (rotated weekly, 8 kept); last result in `/var/backups/glowfit/STATUS` |
| Decrypt | Only with the owner's private key — **never on the VPS** |

## What lives where

| Item | Location | In git? |
|---|---|---|
| Backup / restore / setup scripts | `server/scripts/backup-db.sh`, `backup-nightly.sh`, `restore-db.sh`, `setup-vps.sh` | ✅ this repo |
| Cron + logrotate files | `server/backup/cron.d-glowfit-backup`, `server/backup/logrotate-glowfit-backup` (installed copies in `/etc/cron.d/`, `/etc/logrotate.d/`) | ✅ this repo |
| Backup **public** key (encrypt only) | `server/backup/glowfit-backup-public-key.asc` | ✅ this repo — safe, it cannot decrypt |
| Encrypted backups (off-server) | Private repo `soniadcam2025/glowfit30-backups`: tags `nightly/*` (automatic) and releases `db-*` (manual) | Private repo |
| Encrypted backups (on the VPS) | `/var/backups/glowfit/` (root-only, `chmod 700`) | No |
| Upload credential | SSH **deploy key** on `glowfit30-backups` only, write access. Private half `/root/.config/glowfit-backup/deploy_key` (root, 600), GitHub host keys pinned in `known_hosts` beside it | **Never** |
| Backup **private** key (decrypt) | Owner's custody — password manager + offline copy. Created at `C:\Users\sprsr\glowfit-backup-key\glowfit-backup-PRIVATE-key.asc` | **Never** |
| Database role password | Owner's secret store; set on the server in `api/.env` | **Never** |

Key fingerprint: **`9C0F 9D4B 89B2 4B13 15E4  4998 66CA E44F DBA4 4036`** (ed25519 / cv25519, OpenPGP, no expiry).

Lose the private key and every existing backup is unreadable. Keep at least two copies of it in different places (e.g. password manager attachment + encrypted USB), and do not keep it on the VPS.

### Why a deploy key, and what it can and cannot do

GitHub release uploads need an API token, and fine-grained tokens can only be created by hand in the web UI. A **deploy key** is narrower: it is bound to one repository and cannot see or touch anything else on the account — verified 2026-10-14, a push with it to the public `glowfit30` repo is refused (`Permission ... denied to deploy key`). It can, however, create and delete refs in `glowfit30-backups`. Someone with root on the VPS could therefore delete the backups stored there (they could never *read* them — no private key on the server). Mitigation: keep an occasional copy outside GitHub (download a monthly tag to the offline medium holding the private key).

To revoke it: GitHub → `glowfit30-backups` → Settings → Deploy keys → "glowfit-vps nightly backup", or `gh api -X DELETE repos/soniadcam2025/glowfit30-backups/keys/166438156`.

## Backup format

Each backup (`server/scripts/backup-db.sh`) produces:

| File | Contents |
|---|---|
| `glowfit_db-<UTC>.dump.gpg` | `pg_dump --format=custom --compress=9` of `glowfit_db`, encrypted to the public key above |
| `glowfit_db-<UTC>.dump.gpg.sha256` | sha256 of the `.gpg` file |
| `glowfit_db-<UTC>.manifest.txt` | date, host, PostgreSQL + pg_dump versions, table count, sizes, sha256 of both the plaintext dump and the `.gpg` |
| `roles-<UTC>.sql.gpg` | role definitions from `pg_dumpall --roles-only --no-role-passwords` — **no passwords** |

`pg_dump` takes one consistent snapshot without blocking the app. Before encrypting, the script confirms the dump is non-empty, readable by `pg_restore --list`, and has at least 15 tables with data (production has 19); otherwise it exits non-zero and deletes the partial output. `backup-nightly.sh` additionally refuses to upload anything that still starts with the plaintext `PGDMP` signature.

Each nightly tag is a single orphan commit containing only that night's four files plus a `.gitattributes` (`* binary`, so git on Windows doesn't rewrite the `.sha256`/`.txt` files to CRLF). Nothing is pushed to a branch, so deleting a tag really removes that backup from the repository's history.

**What the database depends on** (not inside the dump, recreate first):

- Role `glowfit_user` — `LOGIN`, not superuser, no `CREATEDB`. Owns `glowfit_db` and its `public` schema. Password is set fresh on restore.
- Extensions: `pgcrypto` (recreated by the restore itself — it is a trusted extension in PostgreSQL 13+), `plpgsql`.
- Encoding `UTF8`, collation `en_US.UTF-8`.

## Failure handling

- Any failed step (dump, sanity check, encryption, push, verification) makes `backup-nightly.sh` exit non-zero, log `FAILED … backup <stamp> is NOT safely off-server` and write `FAILED` to `/var/backups/glowfit/STATUS`. Remote pruning only ever runs after the current night's upload has been verified.
- The encrypted files stay on the VPS for 14 days whether or not the upload worked, so a fixed upload problem can be retried by hand (see below) without losing nights.
- The VPS has no mail transport, so it cannot alert by itself. The **Backup freshness** workflow in `glowfit30-backups` is the alarm: it runs on GitHub's infrastructure, so it also catches a dead VPS, broken cron, or a revoked key. GitHub emails the owner when a scheduled run fails — make sure Actions notifications are on (GitHub → Settings → Notifications → Actions).
- Tested 2026-10-14: a run pointed at a non-existent repository exited 128 and recorded `FAILED`.

```bash
# On the VPS — what happened last night?
cat /var/backups/glowfit/STATUS
tail -50 /var/log/glowfit-backup.log
# Re-run by hand (takes ~10 s)
bash /var/www/glowfit/server/scripts/backup-nightly.sh
```

## Backup history

Automatic nightlies are listed by `git ls-remote --tags git@github.com:soniadcam2025/glowfit30-backups.git 'nightly/*'`. Restore-tested backups are recorded here:

| Date (UTC) | Location | PostgreSQL | Dump | Encrypted | sha256 (`.gpg`) | Restore test |
|---|---|---|---|---|---|---|
| 2026-10-14 14:17 | release [`db-20261014T141709Z`](https://github.com/soniadcam2025/glowfit30-backups/releases/tag/db-20261014T141709Z) | 14.24 | 77,647 B | 47,697 B | `1768266c97ff6a011354e57ded48f8e4b2dfd6a60014dc2c1028b396503ae402` | ✅ 19/19 tables, row counts + schema identical to production |
| 2026-10-14 14:40 | tag `nightly/20261014T144035Z` (first automatic upload) | 14.24 | 77,647 B | 47,698 B | `2217b96a2d2254a22c726b5883a8980df19578dc2117300d35a4a0975b84d989` | ✅ downloaded from GitHub, decrypted with the owner key (plaintext sha256 `6662c511…` = manifest), restored into a temp DB: 19/19 tables, 765 rows, 21 migrations, identical to production |

## Making an extra backup by hand

On the VPS, as root — same path as the nightly run, including upload and verification:

```bash
bash /var/www/glowfit/server/scripts/backup-nightly.sh
```

A one-off GitHub *release* (e.g. before a risky migration) from a machine with `gh` logged in as the owner:

```bash
scp 'glowfit:/var/backups/glowfit/*<UTC>*' .
sha256sum -c glowfit_db-<UTC>.dump.gpg.sha256
gh release create db-<UTC> --repo soniadcam2025/glowfit30-backups \
  --title "glowfit_db <date>" --notes "see manifest" \
  glowfit_db-<UTC>.dump.gpg glowfit_db-<UTC>.dump.gpg.sha256 \
  glowfit_db-<UTC>.manifest.txt roles-<UTC>.sql.gpg
```

Releases (`db-*`) are never pruned automatically.

## Downloading a backup

```bash
# Nightly tag — note core.autocrlf=false (needed on Windows for tags made before the .gitattributes fix)
git -c core.autocrlf=false clone --depth 1 --branch nightly/<UTC> \
  https://github.com/soniadcam2025/glowfit30-backups.git backup-<UTC>
# Manual release
gh release download db-<UTC> --repo soniadcam2025/glowfit30-backups
```

## Verifying a backup (without restoring)

```bash
sha256sum -c glowfit_db-<UTC>.dump.gpg.sha256            # file intact
gpg --import glowfit-backup-PRIVATE-key.asc              # once, on a trusted machine
gpg --decrypt glowfit_db-<UTC>.dump.gpg > check.dump     # key works
sha256sum check.dump                                     # == dump_sha256 in the manifest
pg_restore --list check.dump | grep -c ' TABLE DATA '    # 19 today
shred -u check.dump 2>/dev/null || rm -f check.dump      # don't leave plaintext around
```

## Restoring

`server/scripts/restore-db.sh` restores into a **new** database only. It refuses if the target database already exists — including the live `glowfit_db` — so it cannot overwrite anything by accident. It checks the `.sha256` if present, decrypts in a throwaway keyring, restores in a single transaction (all or nothing), and prints row counts.

```bash
# 1. The owning role must exist (choose a NEW password; it goes into api/.env)
sudo -u postgres createuser --pwprompt glowfit_user

# 2. Put the backup, its .sha256 and the private key on the server (root-only)
install -m 600 glowfit-backup-PRIVATE-key.asc /root/
#    (scp glowfit_db-<UTC>.dump.gpg and .sha256 into /root/ as well)

# 3. Restore into a fresh database
PRIVATE_KEY=/root/glowfit-backup-PRIVATE-key.asc \
  bash /var/www/glowfit/server/scripts/restore-db.sh /root/glowfit_db-<UTC>.dump.gpg glowfit_db glowfit_user

# 4. Remove the private key from the server again
shred -u /root/glowfit-backup-PRIVATE-key.asc
```

On the **live** server the private key should not be copied over at all. To test a backup there, decrypt on your own machine, copy the plaintext dump over SSH to a root-only path, restore it under another name, then drop it — never restore over the live database:

```bash
gpg --decrypt glowfit_db-<UTC>.dump.gpg > restore.dump          # on your machine
scp restore.dump glowfit:/root/restore.dump && rm restore.dump
ssh glowfit 'bash /var/www/glowfit/server/scripts/restore-db.sh /root/restore.dump glowfit_restore_test glowfit_user \
  && sudo -u postgres dropdb glowfit_restore_test; shred -u /root/restore.dump'
```

To **replace** a live database with a backup (disaster recovery on the same server): stop the API (`sudo -u sprsadmin pm2 stop glowfit-api`), rename the old database rather than dropping it (`ALTER DATABASE glowfit_db RENAME TO glowfit_db_broken_<date>;`), restore into `glowfit_db`, start the API, and only drop the old copy once the app is verified.

After any restore, `npx prisma migrate deploy` in `api/` is safe and should report no pending migrations. **Never run `prisma migrate dev` against a real database** — schema drift in five tables would be "fixed" destructively (see `TODO.md`).

## Restore tests

A backup that has never been restored is a hope, not a backup. Monthly (and after any schema migration):

1. Download the newest `nightly/*` tag, `sha256sum -c`.
2. Decrypt with the owner key; compare the plaintext sha256 to `dump_sha256` in the manifest.
3. Restore as `glowfit_restore_test` (procedure above), compare row counts with production, drop it.
4. Add a row to "Backup history" above.

## Limits

- GitHub rejects files over 100 MB in a git push. The encrypted dump is ~48 KB today (database ~10 MB on disk); when it passes ~50 MB, move off-server storage to object storage (a separate Vultr bucket with a write-only key is the natural next step) or GitHub releases (2 GB per file).
- GitHub recommends repositories stay under ~1 GB. Retention keeps ~42 backups, ~2 MB today.
- Actions minutes: the freshness check uses well under a minute a day, inside the free private-repo allowance.

## Media is NOT in the database backup

Reviewed 2026-10-14 (read-only, from the VPS with the app's own credentials):

| Bucket | Objects | Size | Versioning | Lifecycle | Storage class |
|---|---|---|---|---|---|
| exercises (`VULTR_S3_BUCKET_EXERCISES`) | 228 (162 webp, 34 mp4, 32 jpg/jpeg/png) | 3.6 MB | never enabled | `MoveObjectsToArchive`: transition to `VULTR_ARCHIVE` after **0 days** | all `VULTR_ARCHIVE` |
| diet (`VULTR_S3_BUCKET_DIET`) | 5 | < 0.1 MB | never enabled | same rule | all `VULTR_ARCHIVE` |

- The database stores only URLs. Images and videos survive losing the VPS, but **there is exactly one copy**. Without versioning, a deleted or overwritten object — by mistake, by a bug, or by anyone holding the S3 keys in `api/.env` — is gone, and so is a deleted bucket or a closed Vultr account.
- Every object is moved to the `VULTR_ARCHIVE` class on upload. The app has been serving them normally (images via the Cloudflare Worker, verified 2026-08-08), so reads work today, but check Vultr's pricing/retrieval terms for that class before relying on it as a design decision — this rule was not created by anything in this repository.
- **Recommended next step (not done — needs your decision):** enable versioning on both buckets, plus a periodic `rclone sync` to a separate bucket or provider with its own credentials. At ~4 MB this costs nothing meaningful. The GitHub backups repo is not a good home for media.
