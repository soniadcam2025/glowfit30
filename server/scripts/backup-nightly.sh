#!/usr/bin/env bash
#
# Nightly: back up glowfit_db, ship the encrypted files to the private
# soniadcam2025/glowfit30-backups repository, prove the upload, prune old ones.
#
# Run by /etc/cron.d/glowfit-backup (see BACKUP_RESTORE.md). Safe to run by hand:
#   sudo bash /var/www/glowfit/server/scripts/backup-nightly.sh
#
# Storage mechanism: each backup is one orphan commit holding only that night's
# files, published as tag nightly/<UTC stamp>. Nothing is ever pushed to a
# branch, so deleting an old tag really drops that backup from the repository.
# Releases made by hand (tags db-*) are never touched by this script.
#
# Credential: an SSH *deploy key* registered on glowfit30-backups only. It can
# read/write that one repository and nothing else on the account; it lives in
# $CRED_DIR (root-only) and never in git or in logs.
#
# Only encrypted files leave the server. Every failure exits non-zero, is
# logged, and is recorded in $BACKUP_DIR/STATUS; a separate GitHub Actions
# check in the backups repo alerts if no fresh backup arrives.

set -Eeuo pipefail
umask 077

REPO_DIR="${REPO_DIR:-/var/www/glowfit}"
DB_NAME="${DB_NAME:-glowfit_db}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/glowfit}"
CRED_DIR="${CRED_DIR:-/root/.config/glowfit-backup}"
BACKUP_REMOTE="${BACKUP_REMOTE:-git@github.com:soniadcam2025/glowfit30-backups.git}"
REMOTE_DAILY_DAYS="${REMOTE_DAILY_DAYS:-30}"      # keep every nightly this young
REMOTE_MONTHLY_DAYS="${REMOTE_MONTHLY_DAYS:-365}" # plus the first nightly of each month this young
REMOTE_MIN_KEEP="${REMOTE_MIN_KEEP:-7}"           # never prune below this many

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
TAG="nightly/$STAMP"
STATUS_FILE="$BACKUP_DIR/STATUS"
WORK=""

log() { echo "$(date -u +%FT%TZ) [nightly] $*"; }
record() { mkdir -p "$BACKUP_DIR"; printf '%s %s %s\n' "$(date -u +%FT%TZ)" "$1" "$2" > "$STATUS_FILE"; }
on_error() {
  local rc=$? line=$1
  log "FAILED (exit $rc at line $line) — backup $STAMP is NOT safely off-server"
  record FAILED "stamp=$STAMP line=$line exit=$rc"
  exit "$rc"
}
trap 'on_error $LINENO' ERR
trap '[[ -n "$WORK" ]] && rm -rf "$WORK"' EXIT

[[ $EUID -eq 0 ]] || { echo "run as root" >&2; exit 1; }
[[ -f "$CRED_DIR/deploy_key" ]] || { log "missing $CRED_DIR/deploy_key"; record FAILED "no deploy key"; exit 1; }
[[ -f "$CRED_DIR/known_hosts" ]] || { log "missing $CRED_DIR/known_hosts"; record FAILED "no known_hosts"; exit 1; }
export GIT_SSH_COMMAND="ssh -i $CRED_DIR/deploy_key -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=$CRED_DIR/known_hosts"
export GIT_TERMINAL_PROMPT=0
git_q() { git -c init.defaultBranch=backup -c advice.detachedHead=false "$@"; }

log "start $STAMP"

# ── 1. Dump + verify + encrypt (backup-db.sh exits non-zero on any doubt) ────
BACKUP_STAMP="$STAMP" bash "$REPO_DIR/server/scripts/backup-db.sh"
FILES=(
  "${DB_NAME}-${STAMP}.dump.gpg"
  "${DB_NAME}-${STAMP}.dump.gpg.sha256"
  "${DB_NAME}-${STAMP}.manifest.txt"
  "roles-${STAMP}.sql.gpg"
)
for f in "${FILES[@]}"; do [[ -s "$BACKUP_DIR/$f" ]] || { log "expected file missing: $f"; false; }; done
# Belt and braces: nothing unencrypted may be shipped.
for f in "${FILES[0]}" "${FILES[3]}"; do
  head -c 5 "$BACKUP_DIR/$f" | grep -q '^PGDMP' && { log "$f is NOT encrypted — refusing to upload"; false; }
done

# ── 2. Publish as an orphan commit + tag ─────────────────────────────────────
WORK="$(mktemp -d)"
mkdir "$WORK/up" && cd "$WORK/up"
git_q init -q
git_q checkout -q --orphan backup
for f in "${FILES[@]}"; do cp "$BACKUP_DIR/$f" .; done
# Stop git on Windows (core.autocrlf) rewriting the .sha256/.txt files on checkout.
echo '* binary' > .gitattributes
git_q add -- .gitattributes "${FILES[@]}"
git_q -c user.name="glowfit-vps backup" -c user.email="backups@glowfit30.com" \
  commit -q -m "glowfit_db backup $STAMP" -m "$(cat "${FILES[2]}")"
git_q tag "$TAG"
git_q remote add origin "$BACKUP_REMOTE"
git_q push -q origin "refs/tags/$TAG"
log "pushed $TAG"

# ── 3. Prove it: fetch it back fresh and compare byte for byte ───────────────
cd "$WORK" && git_q clone -q --depth 1 --branch "$TAG" "$BACKUP_REMOTE" verify
cd "$WORK/verify"
sha256sum -c --quiet "${FILES[1]}"
for f in "${FILES[@]}"; do cmp -s "$f" "$BACKUP_DIR/$f" || { log "remote copy of $f differs"; false; }; done
log "verified remote copy (sha256 $(cut -d' ' -f1 "${FILES[1]}"))"

# ── 4. Remote retention (nightly/* only, after a verified upload) ────────────
now=$(date -u +%s)
mapfile -t TAGS < <(git ls-remote --tags --refs "$BACKUP_REMOTE" 'refs/tags/nightly/*' \
  | awk '{print $2}' | sed 's#refs/tags/##' | sort)
declare -A month_seen=()
DELETE=()
for t in "${TAGS[@]}"; do
  ts="${t#nightly/}"
  [[ "$ts" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})T ]] || continue
  age_days=$(( (now - $(date -u -d "${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}" +%s)) / 86400 ))
  month="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
  first_of_month=0
  [[ -z "${month_seen[$month]:-}" ]] && { first_of_month=1; month_seen[$month]=1; }
  if (( age_days <= REMOTE_DAILY_DAYS )); then continue; fi
  if (( first_of_month && age_days <= REMOTE_MONTHLY_DAYS )); then continue; fi
  DELETE+=("$t")
done
if (( ${#TAGS[@]} - ${#DELETE[@]} >= REMOTE_MIN_KEEP )) && (( ${#DELETE[@]} )); then
  for t in "${DELETE[@]}"; do git_q push -q "$BACKUP_REMOTE" ":refs/tags/$t" && log "pruned remote $t"; done
fi
log "remote holds $(( ${#TAGS[@]} - ${#DELETE[@]} )) nightly backups"

record OK "stamp=$STAMP tag=$TAG sha256=$(cut -d' ' -f1 "$BACKUP_DIR/${FILES[1]}")"
log "done $STAMP"
