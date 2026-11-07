#!/usr/bin/env bash
# Usage: docker-deploy.sh            -> deploy every conf-deploy/*.conf in turn (cron entry point)
#        docker-deploy.sh foo.conf   -> deploy one repo
set -Eeuo pipefail

# Cron runs with a minimal PATH; make sure docker/git/flock are found.
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH:-}"

CONF_DIR="${CONF_DIR:-$(cd "$(dirname "$0")" && pwd)/conf-deploy}"

# Dispatcher: one child process per repo so one failure can't stop the rest.
if [[ $# -eq 0 ]]; then
  failed=0
  for conf in "${CONF_DIR}"/*.conf; do
    [[ -e "${conf}" ]] || { echo "No configs in ${CONF_DIR}" >&2; exit 1; }
    "$0" "${conf}" || { echo "FAILED: ${conf}" >&2; failed=1; }
  done
  exit "${failed}"
fi

# Worker: load config, apply defaults derived from NAME
source "$1"
: "${NAME:?NAME missing in $1}"
REPO_DIR="${REPO_DIR:-${HOME}/${NAME}}"
COMPOSE_DIR="${COMPOSE_DIR:-${REPO_DIR}}"          # dir holding the compose file
STATE_DIR="${STATE_DIR:-${HOME}/shared/${NAME}}"
STATE_FILE="${STATE_DIR}/last_deployed_commit"
LOG_DIR="${LOG_DIR:-${HOME}/logs/${NAME}-deploy}"
LOCK_FILE="${LOCK_FILE:-${HOME}/.${NAME}-deploy.lock}"
REMOTE="${REMOTE:-origin}"
BRANCH="${BRANCH:-master}"
LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-30}"
PULL_IMAGES="${PULL_IMAGES:-}"                     # space-separated, for `docker pull`
ALWAYS_REDEPLOY="${ALWAYS_REDEPLOY:-0}"            # 1 = redeploy even with no new commit

exec 9>"${LOCK_FILE}"
if ! flock -n 9; then
  echo "[${NAME}] Another run is in progress, exiting."
  exit 0
fi

mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/$(date +%F_%H%M%S).txt"

exec > >(tee "${LOG_FILE}") 2>&1
export PS4='+ [$(date "+%F %T")] '
set -x

log() { printf '\n=== %s ===\n' "$*"; }

trap 'rc=$?; printf "\n!!! [%s] FAILED (exit %d) at line %d: %s\n" "${NAME}" "$rc" "${LINENO}" "${BASH_COMMAND}" >&2; exit "$rc"' ERR

log "[${NAME}] Run started: $(date -Is)"
find "${LOG_DIR}" -maxdepth 1 -name '*.txt' -mtime "+${LOG_RETENTION_DAYS}" -delete

# Step 1: update the repo (always match the remote)
log "Step 1: fetch and reset to ${REMOTE}/${BRANCH} in ${REPO_DIR}"
cd "${REPO_DIR}"
GIT_TERMINAL_PROMPT=0 git fetch "${REMOTE}" "${BRANCH}"
git reset --hard "${REMOTE}/${BRANCH}"

current_commit=$(git rev-parse HEAD)
last_commit=""
[[ -f "${STATE_FILE}" ]] && last_commit=$(<"${STATE_FILE}")

if [[ "${current_commit}" == "${last_commit}" && "${ALWAYS_REDEPLOY}" != "1" ]]; then
  log "No new commits since last successful deploy (${current_commit}), skipping"
  exit 0
fi

# Step 2: redeploy
cd "${COMPOSE_DIR}"

log "Step 2: docker compose down"
docker compose down

for img in ${PULL_IMAGES}; do
  log "Step 3: docker pull ${img}"
  docker pull "${img}"
  # OR
  # docker compose pull             # I use this ;)
done

log "Step 4: docker compose up --build -d"
docker compose up --build -d

# Step 5: record success
mkdir -p "${STATE_DIR}"
printf '%s\n' "${current_commit}" > "${STATE_FILE}"
log "Done: deployed commit ${current_commit} ($(date -Is))"
