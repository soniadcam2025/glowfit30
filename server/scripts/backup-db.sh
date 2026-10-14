#!/usr/bin/env bash
#
# Encrypted PostgreSQL backup for GlowFit 30.
#
# Produces, in $BACKUP_DIR:
#   glowfit_db-<UTC stamp>.dump.gpg      pg_dump custom format, encrypted to the
#                                        backup public key (server can encrypt,
#                                        never decrypt — the private key lives
#                                        off-server with the owner)
#   glowfit_db-<UTC stamp>.manifest.txt  date, versions, sizes, sha256 of both
#                                        the plaintext dump and the .gpg file
#   roles-<UTC stamp>.sql.gpg            role definitions, NO passwords
#
# The plaintext dump is verified with `pg_restore --list` before encryption and
# deleted afterwards unless KEEP_PLAINTEXT=1 (used for restore tests only).
#
# Read-only against the database. Never touches the live schema or data.
#
# Usage (on the VPS, as root):
#   bash server/scripts/backup-db.sh
# Env overrides:
#   DB_NAME, BACKUP_DIR, PUBLIC_KEY, RETENTION_DAYS, MIN_TABLES, KEEP_PLAINTEXT
#
# Exit 0 = backup written and verified. Non-zero = no trustworthy backup.

set -Eeuo pipefail
umask 077

REPO_DIR="${REPO_DIR:-/var/www/glowfit}"
DB_NAME="${DB_NAME:-glowfit_db}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/glowfit}"
PUBLIC_KEY="${PUBLIC_KEY:-$REPO_DIR/server/backup/glowfit-backup-public-key.asc}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
MIN_TABLES="${MIN_TABLES:-15}"
KEEP_PLAINTEXT="${KEEP_PLAINTEXT:-0}"

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BASE="$BACKUP_DIR/${DB_NAME}-${STAMP}"
DUMP="$BASE.dump"
LOG_PREFIX="[backup:${DB_NAME}]"

log()  { echo "${LOG_PREFIX} $*"; }
fail() { echo "${LOG_PREFIX} ERROR: $*" >&2; exit 1; }

GNUPG_TMP=""
cleanup() {
  [[ -n "$GNUPG_TMP" ]] && rm -rf "$GNUPG_TMP"
  # Never leave a half-written plaintext dump behind on failure.
  if [[ "${BACKUP_OK:-0}" != 1 ]]; then rm -f "$DUMP" "$DUMP.gpg" "$BASE.roles.sql"; fi
}
trap cleanup EXIT

# ── Preflight ────────────────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] || fail "run as root (needs sudo -u postgres and a root-only backup dir)"
for bin in pg_dump pg_dumpall pg_restore gpg sha256sum; do
  command -v "$bin" >/dev/null 2>&1 || fail "$bin not found"
done
[[ -f "$PUBLIC_KEY" ]] || fail "public key not found: $PUBLIC_KEY"
sudo -u postgres psql -At -d "$DB_NAME" -c 'select 1' >/dev/null 2>&1 \
  || fail "cannot connect to database $DB_NAME as postgres"

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

# ── Dump ─────────────────────────────────────────────────────────────────────
# pg_dump runs in a single REPEATABLE READ snapshot, so the dump is consistent
# without locking writers out. `cd /` avoids "could not change directory" noise.
log "dumping $DB_NAME"
( cd / && sudo -u postgres pg_dump --format=custom --compress=9 --no-password "$DB_NAME" ) > "$DUMP"
( cd / && sudo -u postgres pg_dumpall --roles-only --no-role-passwords ) > "$BASE.roles.sql"

# ── Verify the plaintext dump before trusting it ─────────────────────────────
[[ -s "$DUMP" ]] || fail "dump is empty"
TOC="$(pg_restore --list "$DUMP")" || fail "pg_restore cannot read the dump"
TABLES="$(grep -c ' TABLE DATA ' <<<"$TOC" || true)"
(( TABLES >= MIN_TABLES )) || fail "dump has only $TABLES TABLE DATA entries (expected >= $MIN_TABLES)"
DUMP_SHA="$(sha256sum "$DUMP" | cut -d' ' -f1)"
log "dump ok: $(du -h "$DUMP" | cut -f1), $TABLES tables, sha256 $DUMP_SHA"

# ── Encrypt to the public key (throwaway keyring, nothing persisted) ─────────
GNUPG_TMP="$(mktemp -d)"
gpg --homedir "$GNUPG_TMP" --batch --quiet --import "$PUBLIC_KEY"
FPR="$(gpg --homedir "$GNUPG_TMP" --batch --with-colons --list-keys | awk -F: '/^fpr/{print $10; exit}')"
encrypt() {
  gpg --homedir "$GNUPG_TMP" --batch --yes --trust-model always \
      --recipient "$FPR" --output "$2" --encrypt "$1"
}
encrypt "$DUMP" "$DUMP.gpg"
encrypt "$BASE.roles.sql" "$BACKUP_DIR/roles-${STAMP}.sql.gpg"
rm -f "$BASE.roles.sql"
GPG_SHA="$(sha256sum "$DUMP.gpg" | cut -d' ' -f1)"

# ── Manifest (no secrets in here) ────────────────────────────────────────────
cat > "$BASE.manifest.txt" <<EOF
database:          $DB_NAME
created_utc:       $STAMP
host:              $(hostname)
postgres_server:   $(sudo -u postgres psql -At -d "$DB_NAME" -c 'show server_version' 2>/dev/null)
pg_dump:           $(pg_dump --version)
format:            pg_dump custom (-Fc, compress 9), then OpenPGP-encrypted
encrypted_to:      $FPR
tables_with_data:  $TABLES
dump_bytes:        $(stat -c %s "$DUMP")
dump_sha256:       $DUMP_SHA
gpg_file:          $(basename "$DUMP.gpg")
gpg_bytes:         $(stat -c %s "$DUMP.gpg")
gpg_sha256:        $GPG_SHA
roles_file:        roles-${STAMP}.sql.gpg (role definitions only, no passwords)
EOF
sha256sum "$DUMP.gpg" | sed "s#  .*/#  #" > "$DUMP.gpg.sha256"

if [[ "$KEEP_PLAINTEXT" != 1 ]]; then rm -f "$DUMP"; else log "KEEP_PLAINTEXT=1: plaintext left at $DUMP — delete it after testing"; fi
BACKUP_OK=1

# ── Retention ────────────────────────────────────────────────────────────────
find "$BACKUP_DIR" -maxdepth 1 -type f \
  \( -name "${DB_NAME}-*" -o -name 'roles-*' \) -mtime +"$RETENTION_DAYS" -print -delete \
  | sed "s#^#${LOG_PREFIX} pruned #"

log "done: $DUMP.gpg ($(du -h "$DUMP.gpg" | cut -f1)) sha256 $GPG_SHA"
