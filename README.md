# Conduit-container

This repository contains a Dockerized full-stack Conduit application with a Django REST backend and an Angular frontend.
It provides a consistent, container-based runtime for local development and deployment.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quickstart](#quickstart)
  - [1. Clone the repository](#1-clone-the-repository)
  - [2. Configure environment variables](#2-configure-environment-variables)
  - [3. Build and run](#3-build-and-run)
- [Usage](#usage)
  - [Access the application](#access-the-application)
  - [Common Commands](#common-commands)
- [Deployment](#deployment)
  - [How it works](#how-it-works)
  - [Required GitHub secrets](#required-github-secrets)
  - [Triggering a deployment](#triggering-a-deployment)
  - [One-time setup on the VM](#one-time-setup-on-the-vm)
  - [Troubleshooting](#troubleshooting)
- [Project Structure](#project-structure)

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose
- Git

## Quickstart

### 1. Clone the repository

```bash
git clone git@github.com:philippemoluh-byte/conduit-container.git
cd conduit-container
```

### 2. Configure environment variables

Copy the example file and fill in your values:

```bash
cp example.env .env
```

Edit the `.env` file:

```bash
DEBUG=True                                      # Django debug mode (`True` for development, `False` for production)
ALLOWED_HOSTS=<your_ip_hosts>                   # Comma-separated allowed hosts
DJANGO_SETTINGS_MODULE=<your_settings-module>   # Django settings module path
DJANGO_SUPERUSER_USERNAME=<your_admin_user>     # Admin username created on startup
DJANGO_SUPERUSER_EMAIL=<your_admin_email>       # Admin email
DJANGO_SUPERUSER_PASSWORD=<your_password>       # Admin password
DB_NAME=<your_admin_email>                      # Database name
DB_USER=<your_db_user>                          # Database user
DB_PASSWORD=<your_db_password>                  # Database password
DB_HOST=<your_db_host>                          # Database host
DB_PORT=<your_db_port>                          # Database port
CC_SECRET_KEY=<your_secret_key>                 # Django secret key

```

### 3. Build and run

```bash
docker compose --env-file .env up --build -d
```

## Usage

### Access the application

| Page                                               | URL                          |
|----------------------------------------------------|------------------------------|
| conduit application                                | http://<your_ip>:8282        |
| Backend API                                        | http://<your_ip>:8000/api/   |
| Django Administration page (Only for deployed App) | http://<your_ip>:8282/admin/ |

Log in to the Admin panel with the credentials from your `.env`.

### Common Commands

Stream live logs from all services (backend and frontend)

```bash
docker compose logs -f
```

Rebuild the backend only after changes in `conduit-backend/`

```bash
docker compose --env-file .env up --build backend -d
```

Save the Backend logs in the file

```bash
docker compose logs backend > backend-logs.txt
```

Rebuild the frontend (clears the HTML volume so the new build is picked up)

```bash
docker compose down frontend
docker volume rm conduit-container_frontend-html
docker compose --env-file .env up --build frontend -d
```

Stream live logs for the frontend only

```bash
docker compose logs -f frontend
```

Save the frontend logs in the file

```bash
docker compose logs frontend > frontend-logs.txt
```

## Deployment

Deployments to the cloud VM are fully automated through a GitHub Actions workflow defined in
[`.github/workflows/deployment.yaml`](.github/workflows/deployment.yaml). It builds the frontend and
backend images, syncs the deployment configuration, and rolls everything out to the VM over SSH — no
manual file editing or `docker compose up` on the server is needed for a normal release.

### How it works

The workflow consists of two jobs that run one after another:

**1. `build-and-push`** — runs on the GitHub-hosted runner

- Checks out the repository.
- Builds the `frontend` and `backend` images separately (via a build matrix), each from its own
  `Dockerfile` (`conduit-frontend/Dockerfile`, `conduit-backend/Dockerfile`).
- Pushes both images to the GitHub Container Registry (`ghcr.io`), tagged as:
  - `ghcr.io/<owner>/<repo>:frontend-latest` / `ghcr.io/<owner>/<repo>:frontend-<commit-sha>`
  - `ghcr.io/<owner>/<repo>:backend-latest` / `ghcr.io/<owner>/<repo>:backend-<commit-sha>`
- **No image is ever built on the VM itself** — the VM only ever pulls pre-built images.

**2. `deploy-to-cloud-vm`** — runs after `build-and-push` succeeds

- Checks out the repository (needed so `docker-compose.yml` is available to copy to the VM).
- Loads the SSH deploy key into an `ssh-agent` and adds the VM's host key to `known_hosts`.
- Ensures the deployment directory exists on the VM (`mkdir -p`) — safe on a brand-new VM as well as
  on every later run.
- **Generates `.env` from GitHub Secrets**, entirely on the runner, and writes it to a local,
  `chmod 600` file. It is never printed to the logs.
- **Copies `docker-compose.yml` and the generated `.env`** to the VM via `scp`, overwriting whatever
  was there before.
- Opens an SSH connection to the VM, logs in to `ghcr.io` (using the workflow's short-lived
  `GITHUB_TOKEN`), sets `IMAGE_TAG` to the current commit SHA (so `docker-compose.yml` resolves to the
  exact images that were just built, not an arbitrary `latest`), then runs:
  - `docker compose pull` — fetch the new images, no local build
  - `docker compose up -d --remove-orphans` — (re)start the whole stack in detached mode
  - `docker image prune -f` — clean up old, unused images
- Deletes the locally generated `.env` file from the runner's workspace again (runs even if a previous
  step failed, so no secret material lingers).

If any step in either job fails (bad SSH connection, failing build, failed pull, etc.), the workflow
stops and is marked as failed — it will never silently leave a broken deployment on the VM.

> **Important:** Both `docker-compose.yml` and `.env` on the VM are now fully managed by this pipeline
> and get **overwritten on every deployment**. Do not edit either file directly on the VM anymore —
> changes there will be lost on the next push. Make configuration changes in this repository
> (`docker-compose.yml`) or in GitHub Secrets (`.env` values) instead.

### Required GitHub secrets

Configure these under **Settings → Secrets and variables → Actions** in this repository. None of them
are committed to the repo.

**VM connection:**

| Secret            | Purpose                                                                  |
|-------------------|---------------------------------------------------------------------------|
| `CLOUD_VM_HOST`   | IP address or hostname of the cloud VM                                    |
| `CLOUD_VM_USER`   | SSH username used to log in to the VM                                     |
| `CLOUD_VM_PORT`   | SSH port of the VM (usually `22`)                                          |
| `SSH_PRIVATE_KEY` | Private key (matching a public key in the VM's `~/.ssh/authorized_keys`)   |

**Application configuration** (used to generate `.env` on the VM — see [Configure environment
variables](#2-configure-environment-variables) for what each value means):

| Secret                      |
|------------------------------|
| `DEBUG`                       |
| `ALLOWED_HOSTS`                |
| `DJANGO_SETTINGS_MODULE`       |
| `DJANGO_SUPERUSER_USERNAME`    |
| `DJANGO_SUPERUSER_EMAIL`       |
| `DJANGO_SUPERUSER_PASSWORD`    |
| `DB_NAME`                      |
| `DB_USER`                      |
| `DB_PASSWORD`                  |
| `CC_SECRET_KEY`                |

`DB_HOST` and `DB_PORT` are **not** secrets — they're fixed to `db` and `5432` by the workflow, since
that's simply the internal Docker network name/port of the `db` service and never changes per
environment.

`GITHUB_TOKEN` is provided automatically by GitHub Actions for every run and does **not** need to be
created manually — it authenticates against `ghcr.io` for both pushing (from the runner) and pulling
(from the VM) the images.

### Triggering a deployment

The workflow runs automatically:

- On every push to the `main` branch.
- Manual deployment from the feature branch: 
  Go to the Actions tab → "Deployment" → "Run workflow" → in the dropdown "Use workflow from that branch" 
  select the branch → click Run workflow.

It can also be started manually at any time:

1. Go to the **Actions** tab of this repository.
2. Select the **Deployment** workflow in the left sidebar.
3. Click **Run workflow**.

This is useful when you want to re-deploy without pushing a new commit — for example, after updating a
secret value, or to retry following a transient failure. Always re-run the **whole workflow**, not just
`deploy-to-cloud-vm` on its own — otherwise the deploy job may end up looking for images that were never
built for that specific commit.

### One-time setup on the VM

Before the very first deployment, the VM only needs:

1. The public key matching `SSH_PRIVATE_KEY` added to `~/.ssh/authorized_keys` for the deploy user.
2. Docker and the Docker Compose plugin installed, with the deploy user allowed to run `docker` commands
   (e.g. member of the `docker` group).

Everything else — the deployment directory, `docker-compose.yml`, and `.env` — is created and kept
up to date automatically by the workflow from this point on.

### Troubleshooting

- **`Permission denied (publickey,password)`** — the SSH key, username, host, or port secret is wrong,
  or the public key is missing from `~/.ssh/authorized_keys` on the VM.
- **`... not found` when pulling an image** — the `build-and-push` job for that commit either failed or
  hasn't finished yet; re-run the *whole* workflow (not just `deploy-to-cloud-vm`) so both jobs run
  against the same commit. Also double-check that the image tags in `docker-compose.yml` use the
  `<repo>:<service>-<tag>` format (service as a tag prefix), matching what `build-and-push` actually
  pushes — not a nested `<repo>/<service>:<tag>` path.
- **`dependency failed to start: container conduit-db is unhealthy`** — check `docker compose logs db`
  on the VM; this is almost always a mismatch between the database credentials the `db` service receives
  and what the Postgres data volume was originally initialized with (e.g. after changing a `DB_*` secret
  without resetting the volume).

## Project Structure

```text
conduit-container/
├── conduit-backend/        # Django REST API
│   ├── .gitignore          # Backend-specific ignore rules
│   ├── .dockerignore       # Excludes unnecessary files from backend Docker build context
│   ├── Dockerfile          # Builds and runs Django backend with Gunicorn
│   ├── entrypoint.sh       # Runs migrations, collectstatic, creates superuser
│   ├── manage.py           # Django management entry point
│   ├── conduit/            # Django project package (settings, urls, apps)
│   └── requirements.txt    # Python dependencies for the backend service
├── conduit-frontend/       # Angular app served by Nginx
│   ├── .dockerignore       # Excludes unnecessary files from frontend Docker build context
│   ├── .gitignore          # Frontend-specific ignore rules
│   ├── Dockerfile          # Multi-stage build: Angular build output served by Nginx
│   ├── entrypoint.sh       # Seeds built HTML into persistent volume
│   ├── nginx.conf          # Frontend web server config and API reverse proxy settings
│   ├── package.json        # Frontend npm scripts and dependencies
│   └── src/                # Angular source codedocs
├── docs/                   # Additional documentation
├── .github/
│   └── workflows/
│       └── deployment.yaml # CI/CD pipeline: builds images and deploys them to the cloud VM over SSH
├── .gitignore              # Root ignore rules for Python, Node, env files, and editor artifacts
├── example.env             # Template environment file to copy as .env
├── docker-compose.yml      # Defines backend/frontend services, ports, volumes, and environment wiring
└── README.md               # Project documentation and startup instructions
```
