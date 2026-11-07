# docker-builds

One cron entry that rebuilds and pushes Docker images for any number of git repos.
Each repo is described by a small config file in `conf/`.

For each repo the script fetches the remote, skips if the commit was already built successfully, otherwise runs `docker build`, pushes `:<version>` and `:latest` (with retries), and records the commit and version.

Version format: `YYYY.Q.M-D` (year, quarter, month in quarter, day), e.g. `2026.4.2-6`.

## Layout

```
docker-builds/
├── docker-build.sh
├── README.md
└── conf/
    ├── myapp.conf        # one file per repo
    └── myapp2.conf
```

## Requirements

- `bash`, `git`, `docker`, `flock` (util-linux), `find`, `tee`
- Each repo already cloned locally, with a `Dockerfile` at its root
- Git remote credentials that work non-interactively (SSH key or stored token)
- Docker logged in to the registry: `docker login`

## Setup

1. Make the script executable:
   ```bash
   chmod +x docker-build.sh
   ```
2. Add one `.conf` file per repo in `conf/` (see below).
3. Test a single repo by hand:
   ```bash
   ./docker-build.sh conf/4get.conf
   ```
4. Add the cron entry (`crontab -e`):
   ```cron
   0 * * * * /full/path/to/docker-builds/docker-build.sh
   ```

Running with no arguments builds every `conf/*.conf` in alphabetical order.

## Config reference

Config files are plain shell, `source`d by the script. Only `NAME` and `IMAGE` are required.

| Variable | Required | Default | Meaning |
|---|---|---|---|
| `NAME` | yes | | Unique short name; used to derive the defaults below |
| `IMAGE` | yes | | Docker image, e.g. `user/app` |
| `REPO_DIR` | no | `~/$NAME` | Local git checkout to build from |
| `VERSION_DIR` | no | `~/shared/$NAME` | Holds `version.txt` and `last_built_commit` |
| `LOG_DIR` | no | `~/logs/$NAME` | Per-run log files |
| `LOCK_FILE` | no | `~/.$NAME-build.lock` | Prevents overlapping runs of the same repo |
| `REMOTE` | no | `origin` | Git remote to fetch |
| `BRANCH` | no | `master` | Branch to build |
| `LOG_RETENTION_DAYS` | no | `30` | Logs older than this are deleted |

### Examples

`conf/4get.conf`:
```bash
NAME=4get
IMAGE=aishik999/4get-arm
REPO_DIR="${HOME}/4get-arm"
REMOTE=gitea
BRANCH=master
LOG_RETENTION_DAYS=30
```

`conf/myapp.conf` (minimal):
```bash
NAME=myapp
IMAGE=aishik999/myapp
BRANCH=main
```

## Adding, pausing, removing a repo

- **Add:** create `conf/<name>.conf`.
- **Pause:** rename to `<name>.conf.disabled`.
- **Remove:** delete the file.

## Behaviour

- **Isolation:** each repo runs in its own process; a failure in one does not stop the others. The dispatcher exits `1` if any repo failed, so cron mail still alerts you.
- **Locking:** per repo. If a build is still running at the next cron tick, that repo is skipped.
- **Sequential:** repos build one after another, so a slow build delays the ones after it.
- **Retry on failure:** the commit is recorded only after both pushes succeed, so a failed build is retried on the next run.
- **Hard reset:** the checkout is reset to `REMOTE/BRANCH` on every run. Don't keep local changes in `REPO_DIR`.

## Logs

Each run writes `LOG_DIR/<version>-<n>.txt` (stdout, stderr and shell trace), and the same output goes to the console.

## Environment overrides

| Variable | Effect |
|---|---|
| `CONF_DIR` | Use a config directory other than `./conf` |

## Notes

- Configs are executed as shell code; only keep trusted files in `conf/`.
- The build context is always the repo root (`docker build .`). Custom Dockerfile paths are not supported.
