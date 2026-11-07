#!/usr/bin/env bash
# Usage: docker-build.sh            -> build every conf/*.conf in turn (cron entry point)
#        docker-build.sh foo.conf   -> build one repo
set -Eeuo pipefail

# Cron runs with a minimal PATH; make sure docker/git/flock are found.
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH:-}"

CONF_DIR="${CONF_DIR:-$(cd "$(dirname "$0")" && pwd)/conf}"

# ---------------------------------------------------------------------------
# Dispatcher: one child process per repo, so a failure/exit in one cannot
# affect the next (set -e is disabled inside `if`, a subshell would not help).
# ---------------------------------------------------------------------------
if [[ $# -eq 0 ]]; then
  failed=0
  for conf in "${CONF_DIR}"/*.conf; do
    [[ -e "${conf}" ]] || { echo "No configs in ${CONF_DIR}" >&2; exit 1; }
    "$0" "${conf}" || { echo "FAILED: ${conf}" >&2; failed=1; }
  done
  exit "${failed}"
fi

# ---------------------------------------------------------------------------
# Worker: load config, apply defaults derived from NAME
# ---------------------------------------------------------------------------
source "$1"
: "${NAME:?NAME missing in $1}"
: "${IMAGE:?IMAGE missing in $1}"
REPO_DIR="${REPO_DIR:-${HOME}/${NAME}}"
VERSION_DIR="${VERSION_DIR:-${HOME}/shared/${NAME}}"
LOG_DIR="${LOG_DIR:-${HOME}/logs/${NAME}}"
LOCK_FILE="${LOCK_FILE:-${HOME}/.${NAME}-build.lock}"
REMOTE="${REMOTE:-origin}"
BRANCH="${BRANCH:-master}"
LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-30}"
VERSION_FILE="${VERSION_DIR}/version.txt"
STATE_FILE="${VERSION_DIR}/last_built_commit"

# Prevent overlapping runs of the same repo (a slow ARM build must not collide)
exec 9>"${LOCK_FILE}"
if ! flock -n 9; then
  echo "[${NAME}] Another run is in progress, exiting."
  exit 0
fi

# ---------------------------------------------------------------------------
# Compute <version> from today's date
# ---------------------------------------------------------------------------
year=$(date +%Y)
month=$((10#$(date +%m)))
day=$((10#$(date +%d)))

quarter=$(( (month - 1) / 3 + 1 ))
month_in_quarter=$(( (month - 1) % 3 + 1 ))

version="${year}.${quarter}.${month_in_quarter}-${day}"

# ---------------------------------------------------------------------------
# Pick the log file, then send stdout, stderr and xtrace to it + the console
# ---------------------------------------------------------------------------
mkdir -p "${LOG_DIR}"
iteration=1
while [[ -e "${LOG_DIR}/${version}-${iteration}.txt" ]]; do
  iteration=$((iteration + 1))
done
LOG_FILE="${LOG_DIR}/${version}-${iteration}.txt"

exec > >(tee "${LOG_FILE}") 2>&1
export PS4='+ [$(date "+%F %T")] '
set -x

log() { printf '\n=== %s ===\n' "$*"; }

trap 'rc=$?; printf "\n!!! [%s] FAILED (exit %d) at line %d: %s\n" "${NAME}" "$rc" "${LINENO}" "${BASH_COMMAND}" >&2; exit "$rc"' ERR

log "[${NAME}] Run started: $(date -Is)"
log "Computed version: ${version}"
log "Log file: ${LOG_FILE}"

# Remove old logs
find "${LOG_DIR}" -maxdepth 1 -name '*.txt' -mtime "+${LOG_RETENTION_DAYS}" -delete

# ---------------------------------------------------------------------------
# Step 1: update the repository (build checkout: always match the remote)
# ---------------------------------------------------------------------------
log "Step 1: cd ${REPO_DIR}"
cd "${REPO_DIR}"

log "Step 2: fetch and reset to ${REMOTE}/${BRANCH}"
GIT_TERMINAL_PROMPT=0 git fetch "${REMOTE}" "${BRANCH}"
git reset --hard "${REMOTE}/${BRANCH}"

current_commit=$(git rev-parse HEAD)
last_built_commit=""
if [[ -f "${STATE_FILE}" ]]; then
  last_built_commit=$(<"${STATE_FILE}")
fi

# Compare against the last *successfully built* commit (not just before/after
# the pull), so a failed build gets retried on the next run.
if [[ "${current_commit}" == "${last_built_commit}" ]]; then
  log "No new commits since last successful build (${current_commit}), skipping"
  exit 0
fi

git pull --no-rebase -X ours

# ---------------------------------------------------------------------------
# Step 3: build the image (tagged with both the version and latest)
# ---------------------------------------------------------------------------
log "Step 3: docker build -t ${IMAGE}:${version} -t ${IMAGE}:latest ."
docker build --pull -t "${IMAGE}:${version}" -t "${IMAGE}:latest" .

# ---------------------------------------------------------------------------
# Step 4: push both tags (with a few retries for transient registry errors)
# ---------------------------------------------------------------------------
push_with_retry() {
  local tag=$1 attempt
  for attempt in 1 2 3; do
    if docker push "${tag}"; then
      return 0
    fi
    echo "Push of ${tag} failed (attempt ${attempt}/3)" >&2
    sleep $((attempt * 10))
  done
  return 1
}

log "Step 4: docker push ${IMAGE}:${version}"
push_with_retry "${IMAGE}:${version}"

log "Step 5: docker push ${IMAGE}:latest"
push_with_retry "${IMAGE}:latest"

# ---------------------------------------------------------------------------
# Step 6: record success (only now, after everything has been pushed)
# ---------------------------------------------------------------------------
mkdir -p "${VERSION_DIR}"
rm -f "${VERSION_FILE}"
printf '%s\n' "${version}" > "${VERSION_FILE}"
printf '%s\n' "${current_commit}" > "${STATE_FILE}"
log "Wrote ${VERSION_FILE}: $(cat "${VERSION_FILE}")"

log "Done: pushed ${IMAGE}:${version} and ${IMAGE}:latest at commit ${current_commit} ($(date -Is))"
