# django-change-me-project

Scalable Django base template for creating new backend projects instantly. Clone, rename, build.

**Stack**: Django 6.0 | DRF 3.17 | PostgreSQL | Docker | Uvicorn

## Quick Start

```bash
# Clone the template
git clone https://github.com/WebArtistas/django-change-me-project.git my-new-api
cd my-new-api

# Rename everything to your project name
./rename-project.sh my-new-api

# Fresh git
rm -rf .git && git init && git add -A && git commit -m "feat: initial project"

# Setup
python -m venv venv && source venv/bin/activate
cp .env.example .env
pip install -r requirements/dev.txt
python manage.py migrate
python manage.py runserver
```

Verify: `curl http://127.0.0.1:8000/api/health/` returns `{"status": "ok", "project": "my-new-api"}`

## Project Structure

```
django-change-me-project/
  manage.py                     # Entry point (defaults to development settings)
  rename-project.sh             # Quick project rename script
  Makefile                      # Common commands: make run, make migrate, make test
  Dockerfile                    # Multi-stage production build (Python 3.12)
  docker-compose.yml            # Local dev: backend + PostgreSQL
  .env.example                  # Environment variable template
  requirements/
    base.txt                    # Django, DRF, django-environ, django-cors-headers
    dev.txt                     # + debug-toolbar, django-extensions, ipdb
    prod.txt                    # + uvicorn, gunicorn, sentry-sdk, psycopg2, whitenoise
  config/
    __init__.py
    settings/
      __init__.py
      base.py                   # Core settings shared by all environments
      development.py            # DEBUG=True, SQLite, CORS open, verbose logging
      production.py             # Security-hardened, PostgreSQL, HSTS, Sentry
      testing.py                # In-memory SQLite, fast password hasher
    urls.py                     # Root URL config: admin + /api/v1/ + /api/health/
    api_urls.py                 # App-specific API routes (empty, ready to fill)
    views.py                    # Health check endpoint
    wsgi.py
    asgi.py
  apps/
    __init__.py                 # Empty, ready for new Django apps
```

## Key Architecture Decisions

- **`config/` not `project_name/`** — Settings directory never needs renaming when cloning the template
- **Split settings** — Base/dev/prod/test instead of one monolithic 700+ line file
- **Environment variables** — All secrets loaded via `django-environ`, never hardcoded
- **Versioned API URLs** — `/api/v1/` prefix for future API versioning
- **Multi-stage Docker** — Smaller production images (builder → runtime separation)
- **CORS pre-configured** — Ready for Angular frontend connection
- **Security-hardened prod** — HSTS, secure cookies, CSRF, content-type nosniff, XSS filter

## Split Settings

| File | When | Key Features |
|------|------|--------------|
| `base.py` | Always | INSTALLED_APPS, MIDDLEWARE, REST_FRAMEWORK, CORS, AUTH |
| `development.py` | Local dev | `DEBUG=True`, SQLite, `CORS_ALLOW_ALL`, verbose logging, browsable API |
| `production.py` | Production | `DEBUG=False`, PostgreSQL, HSTS, secure cookies, Sentry, WhiteNoise |
| `testing.py` | Tests | In-memory SQLite, fast password hasher, no logging |

Switch environments via `DJANGO_SETTINGS_MODULE`:
```bash
# Development (default)
python manage.py runserver

# Production
DJANGO_SETTINGS_MODULE=config.settings.production python manage.py runserver

# Testing
python manage.py test --settings=config.settings.testing
```

## Adding a New Django App

```bash
# Create a new app in the apps/ directory
python manage.py startapp users apps/users

# Add to INSTALLED_APPS in config/settings/base.py:
INSTALLED_APPS = [
    ...
    'apps.users',
]

# Add API routes in config/api_urls.py:
urlpatterns = [
    path('users/', include('apps.users.urls')),
]
```

## Makefile Commands

| Command | Description |
|---------|-------------|
| `make run` | Start dev server |
| `make migrate` | Run migrations |
| `make makemigrations` | Create new migrations |
| `make test` | Run tests (with testing settings) |
| `make shell` | Django shell |
| `make superuser` | Create admin user |
| `make docker-up` | Start Docker containers |
| `make docker-down` | Stop Docker containers |
| `make docker-build` | Build Docker image |
| `make clean` | Remove __pycache__ and compiled files |
| `make check-deploy` | Run production deployment checks |

## Docker

```bash
# Local development with PostgreSQL
docker compose up

# Production build
docker compose -f docker-compose.yml build
```

The multi-stage Dockerfile:
1. **Builder stage** — Installs Python dependencies with build tools
2. **Runtime stage** — Copies only installed packages + app code (no build tools)
3. **Runs** Uvicorn with 4 workers on port 8000

## Security (Production)

The `production.py` settings include:
- `SECURE_HSTS_SECONDS = 31536000` (1 year)
- `SECURE_HSTS_INCLUDE_SUBDOMAINS = True`
- `SECURE_SSL_REDIRECT = True`
- `SESSION_COOKIE_SECURE = True`
- `CSRF_COOKIE_SECURE = True`
- `SECURE_CONTENT_TYPE_NOSNIFF = True`
- `X_FRAME_OPTIONS = 'DENY'`
- Sentry integration (commented, ready to enable)

Run `make check-deploy` to validate production settings.

## Branch Strategy (Future)

The `main` branch is the minimal skeleton. Future branches will represent "flavor presets":

| Branch | Description |
|--------|-------------|
| `main` | Skeleton: settings + URLs + CORS + health check |
| `with-auth` | JWT auth (simplejwt + allauth + dj-rest-auth), users app |
| `with-celery` | Celery + Redis task queue, beat scheduler |
| `with-websockets` | Django Channels + Redis for WebSocket support |
| `with-graphql` | Graphene or Strawberry GraphQL API |
| `api-only` | DRF only, no admin, no templates |
| `full-stack` | Auth + Celery + WebSockets + notifications + email |

## Adapted From

Production-proven patterns from enterprise Django backends serving multiple frontends with Celery, WebSockets, AI integration, payments, and 100k+ users.
