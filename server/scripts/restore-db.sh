#!/usr/bin/env bash
#
# Restore a GlowFit 30 backup into a NEW, EMPTY database.
#
# This script never overwrites anything: it refuses to run if the target
# database already exists — including the live glowfit_db. To replace a
# database you must drop or rename it yourself first, deliberately.
#
# Usage (on the target server, as root):
#   bash server/scripts/restore-db.sh <backup.dump | backup.dump.gpg> <target_db> [owner_role]
#
#   owner_role defaults to glowfit_user and must already exist
#   (create it first — see BACKUP_RESTORE.md; its password is never in a backup).
#
# For an encrypted .gpg backup, point PRIVATE_KEY at the owner's private key file:
#   PRIVATE_KEY=/root/glowfit-backup-PRIVATE-key.asc bash server/scripts/restore-db.sh ...
# The key is imported into a throwaway keyring that is deleted on exit.
#
# If a "<file>.sha256" sits next to the backup, it is checked before anything else.

set -Eeuo pipefail
umask 077

BACKUP="${1:-}"
TARGET_DB="${2:-}"
OWNER="${3:-glowfit_user}"
PRIVATE_KEY="${PRIVATE_KEY:-}"

log()  { echo "[restore] $*"; }
fail() { echo "[restore] ERROR: $*" >&2; exit 1; }

WORK=""
cleanup() { [[ -n "$WORK" ]] && rm -rf "$WORK"; }
trap cleanup EXIT

# ── Inputs ───────────────────────────────────────────────────────────────────
[[ -n "$BACKUP" && -n "$TARGET_DB" ]] || fail "usage: $0 <backup.dump|backup.dump.gpg> <target_db> [owner_role]"
[[ -f "$BACKUP" ]] || fail "backup file not found: $BACKUP"
[[ "$TARGET_DB" =~ ^[a-z_][a-z0-9_]{0,62}$ ]] || fail "target_db must be a plain lowercase identifier"
[[ "$OWNER" =~ ^[a-z_][a-z0-9_]{0,62}$ ]] || fail "owner_role must be a plain lowercase identifier"
[[ $EUID -eq 0 ]] || fail "run as root"
for bin in psql createdb pg_restore sha256sum; do
  command -v "$bin" >/dev/null 2>&1 || fail "$bin not found"
done

pg() { ( cd / && sudo -u postgres "$@" ); }

# ── Safety: never touch an existing database ─────────────────────────────────
EXISTS="$(pg psql -At -d postgres -v db="$TARGET_DB" <<<"select 1 from pg_database where datname = :'db'")"
[[ -z "$EXISTS" ]] || fail "database '$TARGET_DB' already exists — refusing to overwrite it. Pick a new name, or drop/rename it yourself first."
ROLE="$(pg psql -At -d postgres -v r="$OWNER" <<<"select 1 from pg_roles where rolname = :'r'")"
[[ -n "$ROLE" ]] || fail "role '$OWNER' does not exist. Create it first, e.g.: sudo -u postgres createuser --pwprompt $OWNER"

# ── Checksum ─────────────────────────────────────────────────────────────────
if [[ -f "$BACKUP.sha256" ]]; then
  WANT="$(cut -d' ' -f1 < "$BACKUP.sha256")"
  HAVE="$(sha256sum "$BACKUP" | cut -d' ' -f1)"
  [[ "$WANT" == "$HAVE" ]] || fail "checksum mismatch for $BACKUP (expected $WANT, got $HAVE)"
  log "checksum ok ($HAVE)"
else
  log "no $BACKUP.sha256 alongside the backup — checksum not verified"
fi

# ── Decrypt if needed ────────────────────────────────────────────────────────
WORK="$(mktemp -d)"
chmod 755 "$WORK"   # postgres must be able to read the dump inside
DUMP="$BACKUP"
if [[ "$BACKUP" == *.gpg ]]; then
  [[ -n "$PRIVATE_KEY" && -f "$PRIVATE_KEY" ]] || fail "encrypted backup: set PRIVATE_KEY=/path/to/glowfit-backup-PRIVATE-key.asc"
  command -v gpg >/dev/null 2>&1 || fail "gpg not found"
  mkdir -m 700 "$WORK/gnupg"
  gpg --homedir "$WORK/gnupg" --batch --quiet --import "$PRIVATE_KEY"
  DUMP="$WORK/restore.dump"
  gpg --homedir "$WORK/gnupg" --batch --quiet --output "$DUMP" --decrypt "$BACKUP" || fail "decryption failed (wrong key?)"
  rm -rf "$WORK/gnupg"
  log "decrypted"
else
  cp "$BACKUP" "$WORK/restore.dump"; DUMP="$WORK/restore.dump"
fi
chmod 644 "$DUMP"

pg_restore --list "$DUMP" >/dev/null || fail "pg_restore cannot read the dump"
TABLES="$(pg_restore --list "$DUMP" | grep -c ' TABLE DATA ' || true)"
log "dump readable, $TABLES tables with data"

# ── Create + restore (all-or-nothing) ────────────────────────────────────────
log "creating database $TARGET_DB owned by $OWNER"
pg createdb --owner="$OWNER" --encoding=UTF8 --template=template0 "$TARGET_DB"
# Production's public schema is owned by the app role; match it so the dump's
# COMMENT/ownership statements apply cleanly under --role.
pg psql -q -d "$TARGET_DB" -c "ALTER SCHEMA public OWNER TO \"$OWNER\""

log "restoring (single transaction — a failure leaves the new database empty)"
if ! pg pg_restore --dbname="$TARGET_DB" --no-owner --no-acl --role="$OWNER" \
       --single-transaction --exit-on-error "$DUMP"; then
  fail "pg_restore failed. '$TARGET_DB' was created but holds no restored data; drop it with: sudo -u postgres dropdb $TARGET_DB"
fi

# ── Report ───────────────────────────────────────────────────────────────────
log "row counts in $TARGET_DB:"
pg psql -At -d "$TARGET_DB" <<'SQL' | column -t -s'|' | sed 's/^/  /'
select format('select %L as t, count(*) from public.%I', tablename, tablename)
from pg_tables where schemaname = 'public' order by tablename
\gexec
SQL
log "done. Point DATABASE_URL at '$TARGET_DB' to use it."
