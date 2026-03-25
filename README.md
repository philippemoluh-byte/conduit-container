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
DEBUG=True                                     # Django debug mode (`True` for development, `False` for production)
ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0      # Comma-separated allowed hosts
DJANGO_SETTINGS_MODULE=conduit.settings        # Django settings module path
DJANGO_SUPERUSER_USERNAME=admin                # Admin username created on startup
DJANGO_SUPERUSER_EMAIL=admin@example.com       # Admin email
DJANGO_SUPERUSER_PASSWORD=change-this-password # Admin password
```

### 3. Build and run

```bash
docker compose --env-file .env up --build -d
```

## Usage

### Access the application

| Service      | URL                              |
|--------------|----------------------------------|
| Frontend     | http://<your_ip>:8082            |
| Backend API  | http://<your_ip>:8000/api/       |
| Django Admin | http://<your_ip>:8000/admin/     |

Log in to the Admin panel with the credentials from your `.env`.

### Common Commands

Stream live logs from all services (backend and frontend)

```bash
docker compose logs -f
```

Stop all containers

```bash
docker compose down
```

Stop and remove volumes

```bash
docker compose down -v
```

Rebuild the backend only after changes in `conduit-backend/`

```bash
docker compose --env-file .env up --build backend -d
```

Stream live logs for the backend only

```bash
docker compose logs -f backend
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
│   └── src/                # Angular source code
├── .gitignore              # Root ignore rules for Python, Node, env files, and editor artifacts
├── example.env             # Template environment file to copy as .env
├── docker-compose.yml      # Defines backend/frontend services, ports, volumes, and environment wiring
└── README.md               # Project documentation and startup instructions
```
