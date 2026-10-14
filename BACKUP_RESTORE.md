# GlowFit 30 — Database Backup & Restore

How the production database (`glowfit_db`) is backed up, where backups live, how to verify them, and how to restore one. For rebuilding a whole server, see [`RECOVERY.md`](RECOVERY.md).

> **This repository is public.** It holds scripts and the *public* encryption key only. Database dumps, the private key and every password live elsewhere — see "What lives where" below.

## What lives where

| Item | Location | In git? |
|---|---|---|
| Backup / restore / setup scripts | `server/scripts/backup-db.sh`, `restore-db.sh`, `setup-vps.sh` | ✅ this repo |
| Backup **public** key (encrypt only) | `server/backup/glowfit-backup-public-key.asc` | ✅ this repo — safe, it cannot decrypt |
| Encrypted backups | Release assets in the **private** repo [`soniadcam2025/glowfit30-backups`](https://github.com/soniadcam2025/glowfit30-backups/releases) | Private repo, release assets (not git history) |
| Encrypted backups (on the VPS) | `/var/backups/glowfit/` (root-only, `chmod 700`) | No |
| Backup **private** key (decrypt) | Owner's custody — password manager + offline copy. Created at `C:\Users\sprsr\glowfit-backup-key\glowfit-backup-PRIVATE-key.asc` | **Never** |
| Database role password | Owner's secret store; set on the server in `api/.env` | **Never** |

Key fingerprint: **`9C0F 9D4B 89B2 4B13 15E4  4998 66CA E44F DBA4 4036`** (ed25519 / cv25519, OpenPGP, no expiry).

Lose the private key and every existing backup is unreadable. Keep at least two copies of it in different places (e.g. password manager attachment + encrypted USB), and do not keep it on the VPS.

## Backup format

Each backup run (`server/scripts/backup-db.sh`) produces:

| File | Contents |
|---|---|
| `glowfit_db-<UTC>.dump.gpg` | `pg_dump --format=custom --compress=9` of `glowfit_db`, encrypted to the public key above |
| `glowfit_db-<UTC>.dump.gpg.sha256` | sha256 of the `.gpg` file |
| `glowfit_db-<UTC>.manifest.txt` | date, host, PostgreSQL + pg_dump versions, table count, sizes, sha256 of both the plaintext dump and the `.gpg` |
| `roles-<UTC>.sql.gpg` | role definitions from `pg_dumpall --roles-only --no-role-passwords` — **no passwords** |

`pg_dump` takes one consistent snapshot without blocking the app. Before encrypting, the script confirms the dump is non-empty, readable by `pg_restore --list`, and has at least 15 tables with data (production has 19); otherwise it exits non-zero and deletes the partial output.

**What the database depends on** (not inside the dump, recreate first):

- Role `glowfit_user` — `LOGIN`, not superuser, no `CREATEDB`. Owns `glowfit_db` and its `public` schema. Password is set fresh on restore.
- Extensions: `pgcrypto` (recreated by the restore itself — it is a trusted extension in PostgreSQL 13+), `plpgsql`.
- Encoding `UTF8`, collation `en_US.UTF-8`.

## Backup history

| Date (UTC) | Release | PostgreSQL | Dump | Encrypted | sha256 (`.gpg`) | Restore-tested |
|---|---|---|---|---|---|---|
| 2026-10-14 14:17 | [`db-20261014T141709Z`](https://github.com/soniadcam2025/glowfit30-backups/releases/tag/db-20261014T141709Z) | 14.24 | 77,647 B | 47,697 B | `1768266c97ff6a011354e57ded48f8e4b2dfd6a60014dc2c1028b396503ae402` | ✅ 19/19 tables, row counts + schema identical to production |

Plaintext dump sha256 for that backup: `8c61467b14706d5d3a597ebf6888301c6898b4d50c69f82957a867f902fbc49e` — decrypting the release asset with the owner's key reproduces exactly this.

## Making a backup by hand

On the VPS, as root:

```bash
bash /var/www/glowfit/server/scripts/backup-db.sh
ls -l /var/backups/glowfit/
```

Then copy it off the server and upload it (from a machine with `gh` logged in as the repo owner):

```bash
scp 'glowfit:/var/backups/glowfit/*<UTC>*' .
sha256sum -c glowfit_db-<UTC>.dump.gpg.sha256
gh release create db-<UTC> --repo soniadcam2025/glowfit30-backups \
  --title "glowfit_db <date>" --notes "see manifest" \
  glowfit_db-<UTC>.dump.gpg glowfit_db-<UTC>.dump.gpg.sha256 \
  glowfit_db-<UTC>.manifest.txt roles-<UTC>.sql.gpg
# verify the upload round-trips
mkdir verify && cd verify && gh release download db-<UTC> --repo soniadcam2025/glowfit30-backups
sha256sum -c glowfit_db-<UTC>.dump.gpg.sha256
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

To **test** a backup on a server that already has a live `glowfit_db`, restore under another name and drop it afterwards — never restore over the live database:

```bash
PRIVATE_KEY=... bash server/scripts/restore-db.sh /root/<backup>.dump.gpg glowfit_restore_test glowfit_user
sudo -u postgres dropdb glowfit_restore_test
```

To **replace** a live database with a backup (disaster recovery on the same server): stop the API (`sudo -u sprsadmin pm2 stop glowfit-api`), rename the old database rather than dropping it (`ALTER DATABASE glowfit_db RENAME TO glowfit_db_broken_<date>;`), restore into `glowfit_db`, start the API, and only drop the old copy once the app is verified.

After any restore, `npx prisma migrate deploy` in `api/` is safe and should report no pending migrations. **Never run `prisma migrate dev` against a real database** — schema drift in five tables would be "fixed" destructively (see `TODO.md`).

## Nightly backups

**Status: proposed, not installed.** The script is tested; the schedule and off-site copy need two decisions from the owner (below).

### Schedule

`/etc/cron.d/glowfit-backup` on the VPS:

```cron
# m  h  dom mon dow user command
30 2  *   *   *   root  /usr/bin/flock -n /run/glowfit-backup.lock bash /var/www/glowfit/server/scripts/backup-db.sh >> /var/log/glowfit-backup.log 2>&1
```

The VPS keeps 14 days locally (`RETENTION_DAYS`). The database is ~10 MB today and a compressed dump ~50 KB, so space is not a concern for years.

### Off-server copy (decision needed)

A copy on the VPS alone does not survive losing the VPS. Options, all receiving only already-encrypted files:

| Option | Cost | Fit | Needs on the VPS |
|---|---|---|---|
| **A. Vultr Object Storage, separate bucket** (recommended) | Object Storage is already subscribed for media; an extra bucket should fall inside the existing quota at this size (confirm in the Vultr dashboard) | Built for this. Bucket lifecycle rule handles retention (e.g. 30 daily + 12 monthly). Same provider as the VPS, but separate infrastructure | A **write-only** access key scoped to the backup bucket, in a root-only file (`/root/.glowfit-backup.env`) |
| B. GitHub release assets in `glowfit30-backups` | Free | Fine for occasional/manual snapshots (2 GB per file, no total cap documented for releases, but not designed as a backup store) | A fine-grained token with `contents:write` on that one repo |
| C. Pull from a machine you control (`scp glowfit:/var/backups/glowfit/* ...` on a schedule) | Free | Nothing secret on the VPS at all | Nothing — but that machine must be on |

Whichever is chosen, the upload step is appended to the cron line above and must:

- run only if `backup-db.sh` exited 0;
- re-download or `HEAD` the uploaded object and compare size/sha256;
- on failure, keep the local file (retention is longer than one day) and log loudly — wire `/var/log/glowfit-backup.log` into whatever alerting is added (none exists today).

### Restore tests

A backup that has never been restored is a hope, not a backup. Monthly (and after any schema migration):

1. Download the latest backup from off-server storage, `sha256sum -c`.
2. Restore it as `glowfit_restore_test` with `restore-db.sh` (on the VPS or any machine with PostgreSQL 14+).
3. Compare row counts with production; `sudo -u postgres dropdb glowfit_restore_test`.
4. Add a row to "Backup history" above.

## Media is not in the database backup

Uploaded images and videos are stored in **Vultr Object Storage** buckets (`VULTR_S3_BUCKET_EXERCISES`, `VULTR_S3_BUCKET_DIET`), not on the VPS. The database only stores their URLs. They survive losing the VPS, but are **not backed up anywhere else** — a deleted bucket or object is gone. If that matters, enable versioning on the buckets or mirror them periodically (`rclone sync` to a second bucket). Only ~61 media assets exist today.
