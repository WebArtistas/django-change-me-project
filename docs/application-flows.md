# Application Flows

How requests move through the template and how to build on each layer.

---

## Request Lifecycle

Every request follows this path through the stack:

```
Client (browser / Angular / mobile)
  │
  ▼
Uvicorn (ASGI server, production)
  │  or
Django runserver (development)
  │
  ▼
Middleware Stack (in order)
  1. SecurityMiddleware        — HTTPS redirect, HSTS headers
  2. CorsMiddleware            — Cross-origin request handling
  3. SessionMiddleware         — Session cookie management
  4. CommonMiddleware          — URL normalization, Content-Length
  5. CsrfViewMiddleware        — CSRF token validation
  6. AuthenticationMiddleware   — Attaches request.user
  7. MessageMiddleware          — Flash message framework
  8. XFrameOptionsMiddleware    — Clickjacking protection
  │
  ▼
URL Router (config/urls.py)
  ├── /admin/           → Django Admin
  ├── /api/v1/          → config/api_urls.py → Your app routes
  └── /api/health/      → config/views.py → health_check()
  │
  ▼
View / ViewSet
  │
  ▼
Serializer (validation + transformation)
  │
  ▼
Model / ORM → Database
  │
  ▼
Response (JSON)
```

---

## Current Endpoints

The template ships with three URL groups:

| Path | Handler | Purpose |
|------|---------|---------|
| `/admin/` | Django Admin | Built-in admin interface |
| `/api/v1/` | `config/api_urls.py` | Empty — your API routes go here |
| `/api/health/` | `config/views.py` | Returns `{"status": "ok", "project": "change-me-project"}` |

---

## How to Add a New Feature (End-to-End)

### Example: Adding a "Tasks" feature

#### 1. Create the app

```bash
python manage.py startapp tasks apps/tasks
```

#### 2. Register in settings

```python
# config/settings/base.py
INSTALLED_APPS = [
    ...
    'apps.tasks',
]
```

#### 3. Define the model

```python
# apps/tasks/models.py
from django.db import models
from django.conf import settings

class Task(models.Model):
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    completed = models.BooleanField(default=False)
    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='tasks'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return self.title
```

#### 4. Create the serializer

```python
# apps/tasks/serializers.py
from rest_framework import serializers
from .models import Task

class TaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = ['id', 'title', 'description', 'completed', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']
```

#### 5. Create the viewset

```python
# apps/tasks/views.py
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from .models import Task
from .serializers import TaskSerializer

class TaskViewSet(viewsets.ModelViewSet):
    serializer_class = TaskSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Task.objects.filter(owner=self.request.user)

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)
```

#### 6. Wire up URLs

```python
# apps/tasks/urls.py
from rest_framework.routers import DefaultRouter
from .views import TaskViewSet

router = DefaultRouter()
router.register('tasks', TaskViewSet, basename='task')

urlpatterns = router.urls
```

```python
# config/api_urls.py
from django.urls import path, include

urlpatterns = [
    path('tasks/', include('apps.tasks.urls')),
]
```

#### 7. Migrate and test

```bash
python manage.py makemigrations tasks
python manage.py migrate
# Verify: curl http://127.0.0.1:8000/api/v1/tasks/
```

#### Data flow for `POST /api/v1/tasks/`

```
Client POST {"title": "Buy milk"}
  → CorsMiddleware (adds CORS headers)
  → AuthenticationMiddleware (validates JWT / session)
  → URL Router → TaskViewSet.create()
  → TaskSerializer.is_valid() (validates title, description, completed)
  → TaskViewSet.perform_create() (sets owner=request.user)
  → Task.objects.create() → INSERT into tasks_task
  → TaskSerializer(instance).data → JSON response
  → 201 Created {"id": 1, "title": "Buy milk", ...}
```

---

## Settings Flow

Settings are loaded based on `DJANGO_SETTINGS_MODULE`:

```
manage.py / wsgi.py / asgi.py
  │
  │  DJANGO_SETTINGS_MODULE = "config.settings.development" (default)
  │
  ▼
config/settings/development.py
  │
  │  from .base import *    ← imports everything from base.py first
  │
  ▼
config/settings/base.py
  │
  │  reads .env file via django-environ
  │
  ▼
Environment variables (.env file or system)
```

### Override chain

```
.env variables → base.py (shared) → environment file overrides
```

| Setting | base.py | development.py | production.py | testing.py |
|---------|---------|----------------|---------------|------------|
| DEBUG | — | `True` | `False` | `False` |
| Database | — | SQLite | PostgreSQL | In-memory SQLite |
| CORS | Configured | Allow all | Explicit origins | — |
| Renderers | JSONRenderer | + BrowsableAPI | JSONRenderer only | — |
| Logging | — | DEBUG verbose | WARNING only | Silent |
| Passwords | Validators on | Validators on | Validators on | MD5 (fast) |

---

## Docker Flow

```
docker compose up
  │
  ├── db (postgres:16-alpine)
  │   ├── healthcheck: pg_isready
  │   ├── volume: pgdata (persistent)
  │   └── port: 5432
  │
  └── backend (Dockerfile)
      ├── depends_on: db (healthy)
      ├── mounts: .:/app (live code reload)
      ├── command: python manage.py runserver 0.0.0.0:8000
      └── port: 8000
```

### Production Docker build (multi-stage)

```
Stage 1: builder
  ├── python:3.12-slim + gcc + libpq-dev
  ├── pip install → /install prefix
  └── (discarded after build)

Stage 2: runtime
  ├── python:3.12-slim + libpq5 only
  ├── COPY --from=builder /install → /usr/local
  ├── COPY . /app/
  ├── collectstatic
  └── CMD: uvicorn config.asgi:application --workers 4 --port 8000
```

---

## Frontend Connection Flow (Angular)

```
Angular app (localhost:4200)
  │
  │  HTTP request with headers:
  │    Authorization: Bearer <jwt-token>
  │    Content-Type: application/json
  │
  ▼
CorsMiddleware
  │  Checks Origin against CORS_ALLOWED_ORIGINS
  │  Adds Access-Control-Allow-* headers
  │
  ▼
Your API endpoint → JSON response
  │
  ▼
Angular app receives response
```

**Pre-configured CORS headers:**
`accept`, `accept-encoding`, `authorization`, `content-type`, `dnt`, `origin`, `user-agent`, `x-csrftoken`, `x-requested-with`, `x-current-app`

---

## Related Documentation

- [Coding Patterns](coding-patterns.md) — Conventions to follow when building
- [Libraries](libraries.md) — What's included and why
- [User Flows](user-flows.md) — Developer workflow guide
