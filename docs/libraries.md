# Libraries & Dependencies

Every dependency included in the template, why it's there, and how to use it.

---

## Dependency Structure

Requirements are split by environment to keep production images lean:

```
requirements/
  base.txt     ← shared across all environments
  dev.txt      ← extends base + development tools
  prod.txt     ← extends base + production servers & monitoring
```

Install for your environment:

```bash
pip install -r requirements/dev.txt    # development (includes base)
pip install -r requirements/prod.txt   # production (includes base)
```

---

## Base Dependencies (`base.txt`)

These are always installed regardless of environment.

| Package | Version | What It Does | Where It's Used |
|---------|---------|--------------|-----------------|
| **Django** | >=5.2, <7.0 | Web framework — ORM, views, admin, auth, middleware | Entire project |
| **djangorestframework** | >=3.15, <4.0 | REST API toolkit — serializers, viewsets, permissions, pagination | `config/settings/base.py` (REST_FRAMEWORK config), all API views |
| **django-environ** | >=0.12, <1.0 | Reads `.env` files into `os.environ` with type casting | `config/settings/base.py` (env() calls) |
| **django-cors-headers** | >=4.6, <5.0 | Handles Cross-Origin Resource Sharing headers for frontend connections | `config/settings/base.py` (MIDDLEWARE + CORS_* settings) |

### Django (the framework)

Provides everything out of the box:

- **ORM** — Define models in Python, auto-generates migrations
- **Admin** — `/admin/` interface for managing data
- **Auth** — User model, login, permissions, password hashing
- **Middleware** — Security, sessions, CSRF, clickjacking protection
- **Templates** — Server-side rendering (available but not primary for API projects)

```python
# You interact with Django everywhere
from django.db import models
from django.contrib.auth.models import User
from django.urls import path, include
```

### Django REST Framework (DRF)

The API layer on top of Django. Pre-configured in `base.py`:

```python
REST_FRAMEWORK = {
    'DEFAULT_PERMISSION_CLASSES': ['rest_framework.permissions.IsAuthenticated'],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
    'DEFAULT_RENDERER_CLASSES': ['rest_framework.renderers.JSONRenderer'],
}
```

Key concepts:
- **Serializers** — Validate input and format output (like Django forms for APIs)
- **ViewSets** — Class-based views with CRUD built in
- **Routers** — Auto-generate URL patterns from viewsets
- **Permissions** — `IsAuthenticated`, `IsAdminUser`, or custom
- **Pagination** — Automatic page-based pagination (20 items/page)

### django-environ

Reads `.env` file and provides typed access:

```python
import environ
env = environ.Env(DEBUG=(bool, False))
environ.Env.read_env('.env')

SECRET_KEY = env('SECRET_KEY', default='fallback')
DEBUG = env.bool('DEBUG', default=False)
ALLOWED_HOSTS = env.list('ALLOWED_HOSTS', default=[])
```

### django-cors-headers

Allows Angular/React frontends on different ports/domains to call the API. Configured in `base.py`:

```python
CORS_ALLOWED_ORIGINS = env.list('CORS_ALLOWED_ORIGINS', default=[])
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_HEADERS = ['accept', 'authorization', 'content-type', ...]
```

In development, `CORS_ALLOW_ALL_ORIGINS = True` is set to allow any origin.

---

## Development Dependencies (`dev.txt`)

Only installed locally. Never in production.

| Package | Version | What It Does | When to Use |
|---------|---------|--------------|-------------|
| **django-debug-toolbar** | >=5.0, <6.0 | SQL query inspector, template profiler, request/response viewer | Add to `INSTALLED_APPS` + URLs when debugging slow queries |
| **django-extensions** | >=3.2, <4.0 | Extra management commands: `shell_plus`, `show_urls`, `graph_models` | `python manage.py shell_plus` for auto-imported models |
| **ipdb** | >=0.13, <1.0 | Interactive Python debugger with IPython features | Drop `import ipdb; ipdb.set_trace()` anywhere to debug |

### django-debug-toolbar

To enable (not active by default):

```python
# config/settings/development.py
INSTALLED_APPS += ['debug_toolbar']
MIDDLEWARE.insert(0, 'debug_toolbar.middleware.DebugToolbarMiddleware')
INTERNAL_IPS = ['127.0.0.1']

# config/urls.py
if settings.DEBUG:
    urlpatterns += [path('__debug__/', include('debug_toolbar.urls'))]
```

### django-extensions

Useful commands after adding `'django_extensions'` to INSTALLED_APPS:

```bash
python manage.py shell_plus          # Shell with all models auto-imported
python manage.py show_urls           # List all registered URL patterns
python manage.py graph_models -a     # Generate model relationship diagram
python manage.py reset_db            # Drop and recreate database
```

### ipdb

Drop a breakpoint anywhere:

```python
def my_view(request):
    import ipdb; ipdb.set_trace()  # execution pauses here
    return Response(data)
```

---

## Production Dependencies (`prod.txt`)

Only installed in production Docker builds.

| Package | Version | What It Does | Where It's Used |
|---------|---------|--------------|-----------------|
| **uvicorn[standard]** | >=0.30, <1.0 | ASGI server — runs Django async with high concurrency | `Dockerfile` CMD, `config/asgi.py` |
| **gunicorn** | >=23.0, <24.0 | WSGI server — alternative to uvicorn for sync-only deployments | Available as fallback via `config/wsgi.py` |
| **sentry-sdk[django]** | >=2.0, <3.0 | Error tracking and performance monitoring | `config/settings/production.py` (commented, ready to enable) |
| **dj-database-url** | >=2.0, <4.0 | Parses `DATABASE_URL` env var into Django DATABASES dict | `config/settings/production.py` |
| **psycopg2-binary** | >=2.9, <3.0 | PostgreSQL adapter for Python | Required by `dj-database-url` for PostgreSQL connections |
| **whitenoise** | >=6.5, <7.0 | Serves static files directly from Django (no Nginx needed) | `config/settings/production.py` (middleware + storage) |

### uvicorn

The ASGI server that runs Django in production:

```bash
# Development (with auto-reload)
uvicorn config.asgi:application --host 127.0.0.1 --port 8000 --reload

# Production (multi-worker)
uvicorn config.asgi:application --workers 4 --host 0.0.0.0 --port 8000
```

ASGI enables future async features (WebSockets, async views) without changing the server.

### dj-database-url

Converts a single URL string into Django's DATABASES dict:

```python
# .env
DATABASE_URL=postgres://user:pass@host:5432/dbname

# production.py
import dj_database_url
DATABASES = {
    'default': dj_database_url.config(
        default=env('DATABASE_URL'),
        conn_max_age=600,           # keep connections alive 10 min
        conn_health_checks=True,    # verify connection before use
    )
}
```

### whitenoise

Serves static files without Nginx/Apache:

```python
# production.py — already configured
MIDDLEWARE.insert(
    MIDDLEWARE.index('django.middleware.common.CommonMiddleware'),
    'whitenoise.middleware.WhiteNoiseMiddleware',
)
STORAGES = {
    'staticfiles': {
        'BACKEND': 'whitenoise.storage.CompressedManifestStaticFilesStorage',
    },
}
```

Automatically compresses and caches static files with content-based hashes.

### sentry-sdk

Error tracking (commented out, ready to enable):

```python
# config/settings/production.py — uncomment when ready
import sentry_sdk
sentry_sdk.init(
    dsn=env('SENTRY_DSN', default=''),
    traces_sample_rate=0.1,    # 10% of requests traced for performance
    profiles_sample_rate=0.1,
)
```

---

## Common Libraries to Add Next

When you build on this template, these are the most common additions:

| Need | Package | Install |
|------|---------|---------|
| JWT Authentication | `djangorestframework-simplejwt` + `dj-rest-auth` + `django-allauth` | `pip install djangorestframework-simplejwt dj-rest-auth django-allauth` |
| Background Tasks | `celery` + `django-celery-beat` + `redis` | `pip install celery django-celery-beat redis` |
| WebSockets | `channels` + `channels-redis` | `pip install channels channels-redis` |
| File Storage (S3) | `boto3` + `django-storages` | `pip install boto3 django-storages` |
| Email | `sendgrid` or `django-ses` | `pip install sendgrid` |
| Payments | `stripe` | `pip install stripe` |
| API Docs | `drf-spectacular` | `pip install drf-spectacular` |
| Filtering | `django-filter` | `pip install django-filter` |
| Testing | `factory-boy` + `faker` | `pip install factory-boy faker` |

---

## Related Documentation

- [Coding Patterns](coding-patterns.md) — How to use these libraries properly
- [Application Flows](application-flows.md) — How requests flow through the stack
