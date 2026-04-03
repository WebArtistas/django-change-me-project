# TODO

Tracked improvements and planned work for the django-change-me-project template.

**Last updated**: 2026-04-03

---

## High Priority — Template Completeness

### Branch Presets (Planned)

The main branch is the minimal skeleton. These flavor branches are planned:

- [ ] **`with-auth` branch** — JWT authentication preset
  - Add `djangorestframework-simplejwt`, `dj-rest-auth`, `django-allauth`
  - Create `apps/users/` app with custom User model
  - Add registration, login, social login (Google/Apple), password reset endpoints
  - Add JWT token refresh configuration
  - Add email verification flow
  - Update `config/api_urls.py` with auth routes
  - Add auth tests

- [ ] **`with-celery` branch** — Background task preset
  - Add `celery`, `django-celery-beat`, `redis`
  - Create `config/celery.py` configuration
  - Add Redis to `docker-compose.yml`
  - Add `CELERY_*` settings to `base.py`
  - Add example task in a sample app
  - Add `run-celery.sh` convenience script
  - Add beat schedule example

- [ ] **`with-websockets` branch** — Real-time preset
  - Add `channels`, `channels-redis`
  - Create `config/asgi.py` with ProtocolTypeRouter
  - Add example WebSocket consumer with dispatch pattern
  - Add Redis channel layer to `docker-compose.yml`
  - Add WebSocket routing example

- [ ] **`api-only` branch** — Stripped-down API preset
  - Remove `django.contrib.admin`, admin URLs, templates
  - Remove session middleware (JWT only)
  - Add `drf-spectacular` for OpenAPI docs
  - Minimal INSTALLED_APPS

- [ ] **`full-stack` branch** — Everything combined
  - Auth + Celery + WebSockets + email + notifications
  - Base model hierarchy (TimestampMixin, SoftDeleteMixin, BaseModel)
  - Common utilities (pagination, permissions, error handling)
  - Example app demonstrating all patterns

### Core Template Improvements

- [ ] **Add `.pre-commit-config.yaml`** — Configure ruff (linting + formatting), migration check, trailing whitespace. The `pre-commit` package is not in requirements yet but should be added to `dev.txt`.

- [ ] **Add `apps/common/` base app** — Create a `common` app with:
  - `TimestampMixin` abstract model (created_at, updated_at)
  - `SoftDeleteMixin` abstract model (deleted flag + soft_delete method)
  - `BaseModel` combining both
  - Custom exception handler for consistent error responses
  - Pagination classes (Small/Standard/Large)

- [ ] **Add example app** — Create `apps/example/` demonstrating:
  - Model with all field types
  - Serializer with computed fields
  - ViewSet with custom actions
  - URL routing with DefaultRouter
  - Tests (model + API)
  - Can be deleted when starting a real project

- [ ] **Add custom User model** — Django strongly recommends creating a custom User model at project start (hard to change later). Add to main branch:
  ```python
  # apps/users/models.py
  from django.contrib.auth.models import AbstractUser
  class User(AbstractUser):
      pass
  # settings: AUTH_USER_MODEL = 'users.User'
  ```

---

## Medium Priority — Developer Experience

### Documentation

- [ ] **Add `docs/README.md`** — Index page linking to all doc files
- [ ] **Add inline code comments** — `base.py` settings are clean but could use section-header comments for quick scanning
- [ ] **Add `.env.example` documentation** — Comment each variable with description and valid values

### Testing

- [ ] **Add test infrastructure** — Create `conftest.py` or base test class with:
  - Factory for creating test users
  - Authenticated API client helper
  - Test data fixtures

- [ ] **Add `factory-boy` + `faker` to `dev.txt`** — Standard testing libraries for generating test data

- [ ] **Add GitHub Actions CI** — `.github/workflows/ci.yml`:
  - Run `python manage.py test --settings=config.settings.testing`
  - Run `python manage.py makemigrations --check --dry-run`
  - Run ruff linting
  - Run on push to `main` and on PRs

### Docker

- [ ] **Add `.dockerignore`** — Exclude `venv/`, `.git/`, `__pycache__/`, `.env`, `db.sqlite3`, `*.pyc` from Docker context to speed up builds

- [ ] **Add `docker-compose.override.yml`** — Development-only overrides (debug toolbar, volume mounts) separate from base compose file

- [ ] **Add health check to backend service** — Docker health check using `/api/health/` endpoint:
  ```yaml
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8000/api/health/"]
    interval: 30s
    timeout: 10s
    retries: 3
  ```

---

## Low Priority — Nice-to-Have

### Features

- [ ] **Add `drf-spectacular`** — Auto-generate OpenAPI/Swagger docs from viewsets. Add as optional in `dev.txt`.

- [ ] **Add `django-filter` to `base.txt`** — Most API projects need queryset filtering. Pre-configure DRF integration:
  ```python
  REST_FRAMEWORK['DEFAULT_FILTER_BACKENDS'] = [
      'django_filter.rest_framework.DjangoFilterBackend',
      'rest_framework.filters.SearchFilter',
      'rest_framework.filters.OrderingFilter',
  ]
  ```

- [ ] **Add rate limiting** — Pre-configure DRF throttling in `base.py`:
  ```python
  REST_FRAMEWORK['DEFAULT_THROTTLE_CLASSES'] = [
      'rest_framework.throttling.AnonRateThrottle',
      'rest_framework.throttling.UserRateThrottle',
  ]
  REST_FRAMEWORK['DEFAULT_THROTTLE_RATES'] = {
      'anon': '100/hour',
      'user': '1000/hour',
  }
  ```

- [ ] **Add MEDIA_URL/MEDIA_ROOT config** — `base.py` has STATIC_* but no MEDIA_* configuration for user-uploaded files

- [ ] **Add `Procfile`** — For Heroku/Railway/Render deployment:
  ```
  web: uvicorn config.asgi:application --host 0.0.0.0 --port $PORT
  ```

### Code Quality

- [ ] **Add `pyproject.toml`** — Consolidate tool configs (ruff, pytest, mypy) into a single file
- [ ] **Add type hints to `views.py`** — Small file, easy win for documentation
- [ ] **Add `py.typed` marker** — Signal that the package supports type checking

### Template Ecosystem

- [ ] **Create companion Angular template** — `angular-change-me-project` with:
  - Pre-configured API service pointing to this backend
  - Auth interceptor for JWT tokens
  - Environment-based API URL configuration
  - Matching rename script

- [ ] **Create template generator CLI** — `npx create-django-api my-project --with-auth --with-celery` that clones + renames + installs the right branch

---

## Completed

_Move items here when done, with date and commit reference._

- [x] **Multi-stage Dockerfile** — Builder + runtime separation for small production images
- [x] **Split settings** — base/development/production/testing with django-environ
- [x] **Rename script** — `rename-project.sh` handles kebab/snake/Pascal case
- [x] **Docker Compose** — Backend + PostgreSQL with health checks
- [x] **Makefile shortcuts** — 11 common commands
- [x] **CORS pre-configured** — Ready for Angular frontend connection
- [x] **Production security hardening** — HSTS, secure cookies, XSS filter, content-type nosniff
- [x] **Health check endpoint** — `GET /api/health/` for monitoring
- [x] **Project documentation** — Created comprehensive docs (2026-04-03)
  - `docs/application-flows.md` — request lifecycle, settings flow, Docker flow
  - `docs/user-flows.md` — developer workflows (setup, add app, add auth, deploy)
  - `docs/coding-patterns.md` — conventions, model/serializer/viewset patterns
  - `docs/common-utilities.md` — built-in functions and ready-to-copy patterns
  - `docs/libraries.md` — every dependency explained with usage
