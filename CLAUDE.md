# django-change-me-project

## What This Is

A **Django REST API starter template** — not a production application. It has zero business logic, zero models, zero apps. It provides project scaffolding that gets cloned and renamed via `./rename-project.sh <name>` to bootstrap new backends.

If the project has been renamed, this IS the production project and should be treated accordingly.

## Architecture

- **Framework**: Django 5.2+ with Django REST Framework
- **Database**: SQLite (dev) / PostgreSQL (prod via `dj-database-url`)
- **Server**: Uvicorn (ASGI) in production, `runserver` in dev
- **Settings**: Split config — `base.py` → `development.py` / `production.py` / `testing.py`
- **Static files**: WhiteNoise in production
- **Deployment**: Multi-stage Docker, docker-compose with PostgreSQL

## Project Structure

```
config/                    # Project configuration (never rename this)
  settings/
    base.py                # Shared settings, DRF config, CORS
    development.py         # DEBUG=True, SQLite, CORS open
    production.py          # PostgreSQL, HSTS, secure cookies, Sentry
    testing.py             # In-memory SQLite, fast hasher, no logging
  urls.py                  # Root: /admin/ + /api/v1/ + /api/health/
  api_urls.py              # App API routes (empty — add here)
  views.py                 # Health check endpoint
  wsgi.py / asgi.py        # Server entry points
apps/                      # All Django apps go here (empty on template)
requirements/
  base.txt                 # Django, DRF, django-environ, django-cors-headers
  dev.txt                  # + debug-toolbar, django-extensions, ipdb
  prod.txt                 # + uvicorn, gunicorn, sentry, psycopg2, whitenoise
docs/                      # Project documentation
```

## Development Commands

```bash
make run                   # python manage.py runserver
make migrate               # python manage.py migrate
make makemigrations        # python manage.py makemigrations
make test                  # python manage.py test --settings=config.settings.testing
make shell                 # python manage.py shell
make superuser             # python manage.py createsuperuser
make check-deploy          # python manage.py check --deploy (production validation)
make clean                 # remove __pycache__, .pyc, staticfiles
```

## API Routes

| Path | Purpose |
|------|---------|
| `/admin/` | Django admin |
| `/api/v1/` | All app API routes (add in `config/api_urls.py`) |
| `/api/health/` | Health check: `{"status": "ok", "project": "..."}` |

## How to Add Features

All apps go inside `apps/` and routes connect through `config/api_urls.py`:

```bash
python manage.py startapp myapp apps/myapp
```

Then wire up:
1. `config/settings/base.py` → add `'apps.myapp'` to `INSTALLED_APPS`
2. `config/api_urls.py` → add `path('myapp/', include('apps.myapp.urls'))`
3. `apps/myapp/urls.py` → register viewsets with `DefaultRouter`

Standard app file structure:

```
apps/myapp/
  models.py          # Models with timestamps, __str__, Meta
  serializers.py     # ModelSerializer with explicit fields
  views.py           # ViewSet with permissions and get_queryset()
  urls.py            # DefaultRouter registration
  admin.py           # ModelAdmin for each model
  tests.py           # Model + API tests
```

## Key Patterns

### Models

- Always add `created_at = DateTimeField(auto_now_add=True)` and `updated_at = DateTimeField(auto_now=True)`
- Always add `__str__` method
- Always use `related_name` on ForeignKey fields
- Always use `settings.AUTH_USER_MODEL` (not `from django.contrib.auth.models import User`)
- Add `db_index=True` or `Meta.indexes` for fields used in filters/ordering

### ViewSets

- Scope querysets to the current user in `get_queryset()`
- Set owner automatically in `perform_create()`
- Use `@action` decorator for custom endpoints
- Default permission is `IsAuthenticated` (configured in `base.py`)

### Serializers

- Use `ModelSerializer` with explicit `fields` list (never `'__all__'` in production)
- Use separate serializers for list/detail/create when field sets differ
- Mark auto-generated fields in `read_only_fields`

### URLs

- All API routes under `/api/v1/` prefix
- Use `DefaultRouter` for standard CRUD routing
- kebab-case for URL paths, snake_case for Python

### Settings

- All secrets via `env()` from `django-environ` (never hardcoded)
- Add new env vars to both `config/settings/base.py` and `.env.example`
- Shared config in `base.py`, overrides in environment-specific files

### Testing

- Run with `make test` (uses `config.settings.testing` — in-memory SQLite, fast hasher, no logging)
- Use `APITestCase` + `APIClient` for endpoint tests
- Use `force_authenticate()` to skip auth in tests

## What NOT to Do

- Don't create apps at project root — always inside `apps/`
- Don't put app-specific settings in `base.py` — use the environment files
- Don't add `DEBUG=True` to production settings
- Don't commit `.env` files or secrets
- Don't use `'__all__'` in serializer Meta fields for production code
- Don't skip adding `related_name` — it causes conflicts with multiple FKs to the same model
- Don't rename `config/` — it's named generically on purpose so it survives project renames

## Documentation

Detailed guides in `docs/`:

- [Application Flows](docs/application-flows.md) — Request lifecycle, settings chain, Docker flow
- [User Flows](docs/user-flows.md) — Step-by-step developer workflows
- [Coding Patterns](docs/coding-patterns.md) — Conventions and patterns to follow
- [Common Utilities](docs/common-utilities.md) — Built-in functions and starter code
- [Libraries](docs/libraries.md) — Every dependency explained
- [TODO](TODO.md) — Planned work and improvements
