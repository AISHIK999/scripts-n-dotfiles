# docker-deploy

One cron entry that updates any number of git repos from upstream and redeploys their Docker Compose stacks.
Each repo is described by a small config file in `conf-deploy/`.

For each repo the script fetches the remote, skips if the commit was already deployed successfully, otherwise runs:

```
docker compose down
docker pull <image>          # once per image in PULL_IMAGES
docker compose up --build -d
```

The commit is recorded only after all steps succeed, so a failed deploy is retried on the next run.

## Layout

```
docker-builds/
├── docker-deploy.sh
├── README-deploy.md
└── conf-deploy/
    ├── 4get.conf
    └── myapp.conf        # one file per repo
```

This is separate from `docker-build.sh` and its `conf/` directory. The two scripts never read each other's configs.

## Requirements

- `bash`, `git`, `docker` with the `compose` plugin (`docker compose`), `flock` (util-linux), `find`, `tee`
- Each repo already cloned locally, with a compose file in the repo (or in `COMPOSE_DIR`)
- Git remote credentials that work non-interactively (SSH key or stored token)
- Docker logged in to the registry if any image in `PULL_IMAGES` is private: `docker login`

## Setup

1. Make the script executable:
   ```bash
   chmod +x docker-deploy.sh
   ```
2. Add one `.conf` file per repo in `conf-deploy/` (see below).
3. Test a single repo by hand:
   ```bash
   ./docker-deploy.sh conf-deploy/4get.conf
   ```
4. Add the cron entry (`crontab -e`):
   ```cron
   1 0 * * * /full/path/to/docker-builds/docker-deploy.sh
   ```
   This runs daily at 00:01 in the server's timezone. Check it with `date`.

Running with no arguments deploys every `conf-deploy/*.conf` in alphabetical order.

## Config reference

Config files are plain shell, `source`d by the script. Only `NAME` is required.

| Variable | Required | Default | Meaning |
|---|---|---|---|
| `NAME` | yes | | Unique short name; used to derive the defaults below |
| `REPO_DIR` | no | `~/$NAME` | Local git checkout |
| `COMPOSE_DIR` | no | `$REPO_DIR` | Directory containing the compose file (set this if it is in a subfolder) |
| `STATE_DIR` | no | `~/shared/$NAME` | Holds `last_deployed_commit` |
| `LOG_DIR` | no | `~/logs/$NAME-deploy` | Per-run log files |
| `LOCK_FILE` | no | `~/.$NAME-deploy.lock` | Prevents overlapping runs of the same repo |
| `REMOTE` | no | `origin` | Git remote to fetch |
| `BRANCH` | no | `master` | Branch to deploy |
| `LOG_RETENTION_DAYS` | no | `30` | Logs older than this are deleted |
| `PULL_IMAGES` | no | empty | Space-separated images to `docker pull`; empty skips the pull step |
| `ALWAYS_REDEPLOY` | no | `0` | `1` = redeploy even when there are no new commits |

### Examples

`conf-deploy/4get.conf`:
```bash
NAME=myapp
REPO_DIR="${HOME}/myapp"
REMOTE=origin
PULL_IMAGES="dockerhub_user/docker_repo:latest"
ALWAYS_REDEPLOY=0
```

`conf-deploy/myapp.conf` (minimal):
```bash
NAME=myapp
BRANCH=main
```
With that, the repo is expected at `~/myapp`, logs go to `~/logs/myapp-deploy`, and state goes to `~/shared/myapp`.

## Adding, pausing, removing a repo

- **Add:** create `conf-deploy/<name>.conf`.
- **Pause:** rename to `<name>.conf.disabled`.
- **Remove:** delete the file.

## Behaviour

- **Skip logic:** by default a repo is only redeployed when its remote has a commit that was not deployed before. Set `ALWAYS_REDEPLOY=1` to redeploy on every run, for example when you want freshly pushed images in `PULL_IMAGES` picked up with no new commit.
- **Downtime:** the stack is down from `compose down` until `compose up` finishes, including while images pull. If a pull or build fails, the stack stays down until the next successful run.
- **Isolation:** each repo runs in its own process; a failure in one does not stop the others. The dispatcher exits `1` if any repo failed, so cron mail still alerts you.
- **Locking:** per repo. If a run is still going at the next cron tick, that repo is skipped.
- **Sequential:** repos are deployed one after another.
- **Hard reset:** the checkout is reset to `REMOTE/BRANCH` on every run. Don't keep local changes in `REPO_DIR`.

## Using with docker-build.sh

If the same image is built by `docker-build.sh` and deployed here, schedule the deploy after the build normally finishes, otherwise the deploy pulls the previous image. For example, build at 00:01 and deploy at 02:00.

## Logs

Each run writes `LOG_DIR/<date>_<time>.txt` (stdout, stderr and shell trace), and the same output goes to the console.

## Environment overrides

| Variable | Effect |
|---|---|
| `CONF_DIR` | Use a config directory other than `./conf-deploy` |

## Notes

- Configs are executed as shell code; only keep trusted files in `conf-deploy/`.
- The script runs plain `docker compose`, so it uses the compose file in `COMPOSE_DIR` (or whatever `COMPOSE_FILE` is set to in the config).
