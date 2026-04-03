# Common Utilities & Built-in Functions

Everything the template provides out of the box that you can use immediately.

---

## Project-Level Utilities

### Health Check (`config/views.py`)

```python
def health_check(request):
    """Simple health check endpoint."""
    return JsonResponse({
        'status': 'ok',
        'project': 'change-me-project',
    })
```

**Route:** `GET /api/health/`

Use for load balancer health checks, uptime monitoring, and deployment verification. The project name is auto-updated by `rename-project.sh`.

---

## Environment Access (`django-environ`)

Configured in `config/settings/base.py`. Use anywhere settings are loaded:

```python
import environ
env = environ.Env()

# Read values with type casting and defaults
SECRET_KEY = env('SECRET_KEY', default='fallback-key')
DEBUG = env.bool('DEBUG', default=False)
ALLOWED_HOSTS = env.list('ALLOWED_HOSTS', default=['localhost'])
DATABASE_URL = env('DATABASE_URL', default='sqlite:///db.sqlite3')
PAGE_SIZE = env.int('PAGE_SIZE', default=20)
RATE_LIMIT = env.float('RATE_LIMIT', default=1.0)
```

**Supported types:** `str`, `bool`, `int`, `float`, `list`, `tuple`, `dict`, `url`, `path`, `db_url`

---

## DRF Built-in Utilities

### Pagination (pre-configured)

All list endpoints automatically paginate with 20 items per page:

```
GET /api/v1/items/           → page 1 (first 20)
GET /api/v1/items/?page=2    → page 2 (items 21-40)
```

Response format:
```json
{
    "count": 100,
    "next": "http://api.example.com/api/v1/items/?page=2",
    "previous": null,
    "results": [...]
}
```

Override per-viewset:

```python
from rest_framework.pagination import PageNumberPagination

class LargePagination(PageNumberPagination):
    page_size = 100
    page_size_query_param = 'page_size'
    max_page_size = 500

class MyViewSet(viewsets.ModelViewSet):
    pagination_class = LargePagination
```

### Permissions (pre-configured)

Default: `IsAuthenticated` on all endpoints. Built-in classes:

```python
from rest_framework.permissions import (
    IsAuthenticated,          # must be logged in
    IsAdminUser,              # must be staff
    AllowAny,                 # public access
    IsAuthenticatedOrReadOnly,  # read=public, write=authenticated
    DjangoModelPermissions,   # per-model CRUD permissions
)
```

Custom permission:

```python
from rest_framework.permissions import BasePermission

class IsOwner(BasePermission):
    """Only allow owners to edit their own objects."""

    def has_object_permission(self, request, view, obj):
        return obj.owner == request.user
```

### Renderers (pre-configured)

- **Production/default:** JSON only (`JSONRenderer`)
- **Development:** JSON + Browsable API (`BrowsableAPIRenderer`)

The browsable API auto-activates in development, giving you an interactive HTML interface at every endpoint.

---

## Django Built-in Utilities

### Management Commands (via Makefile)

| Command | Shortcut | What It Does |
|---------|----------|-------------|
| `python manage.py runserver` | `make run` | Start dev server on :8000 |
| `python manage.py migrate` | `make migrate` | Apply database migrations |
| `python manage.py makemigrations` | `make makemigrations` | Generate migration files |
| `python manage.py test --settings=config.settings.testing` | `make test` | Run test suite |
| `python manage.py shell` | `make shell` | Interactive Django shell |
| `python manage.py createsuperuser` | `make superuser` | Create admin account |
| `python manage.py check --deploy` | `make check-deploy` | Validate production settings |
| `python manage.py collectstatic` | — | Gather static files for deployment |

### Django ORM Query Patterns

```python
# Get all
items = MyModel.objects.all()

# Filter
active = MyModel.objects.filter(status='active', deleted=False)

# Get or 404
from django.shortcuts import get_object_or_404
item = get_object_or_404(MyModel, pk=1)

# Create
item = MyModel.objects.create(name='New', owner=user)

# Update
MyModel.objects.filter(pk=1).update(status='done')

# Delete
item.delete()

# Aggregate
from django.db.models import Count, Avg
MyModel.objects.aggregate(total=Count('id'), avg_score=Avg('score'))

# Select related (avoid N+1)
MyModel.objects.select_related('owner').filter(status='active')
MyModel.objects.prefetch_related('tags').all()
```

### Auth Utilities

```python
from django.contrib.auth import get_user_model
from django.contrib.auth.hashers import make_password, check_password

User = get_user_model()

# Create user
user = User.objects.create_user(username='john', password='secret123')

# Create superuser
admin = User.objects.create_superuser(username='admin', password='admin123')

# Check password
is_valid = user.check_password('secret123')
```

---

## CORS Utilities (pre-configured)

### Allowed Headers

These headers are accepted from frontend requests:

| Header | Purpose |
|--------|---------|
| `Authorization` | JWT Bearer token |
| `Content-Type` | Request body format |
| `X-CSRFToken` | CSRF protection token |
| `X-Requested-With` | AJAX request identifier |
| `X-Current-App` | Multi-app scoping (custom) |

### Configuration

```python
# .env
CORS_ALLOWED_ORIGINS=http://localhost:4200,https://myapp.com

# Development auto-override:
CORS_ALLOW_ALL_ORIGINS = True  # accepts any origin
```

---

## Docker Utilities

### docker-compose.yml

Pre-configured services:

| Service | Image | Port | Volume |
|---------|-------|------|--------|
| `backend` | Built from Dockerfile | 8000 | `.:/app` (live reload) |
| `db` | postgres:16-alpine | 5432 | `pgdata` (persistent) |

```bash
docker compose up        # start both services
docker compose down      # stop and remove containers
docker compose build     # rebuild images
docker compose logs -f   # follow logs
docker compose exec backend python manage.py migrate  # run command in container
```

### Dockerfile

Multi-stage build produces minimal production images:

| Stage | Base | Contains | Size |
|-------|------|----------|------|
| builder | python:3.12-slim + gcc | Build tools + compiled packages | ~500MB |
| runtime | python:3.12-slim | Only runtime packages + app code | ~150MB |

---

## Rename Script (`rename-project.sh`)

Automates project renaming across all files:

```bash
./rename-project.sh my-cool-api
```

Replaces three naming variants:

| Pattern | From | To |
|---------|------|-----|
| kebab-case | `change-me-project` | `my-cool-api` |
| snake_case | `change_me_project` | `my_cool_api` |
| PascalCase | `ChangeMeProject` | `MyCoolApi` |

Files affected: settings, Docker, compose, URLs, views, README — everything except `.git/`, `venv/`, `__pycache__/`, and the script itself.

---

## Useful Patterns to Build

These utilities don't exist yet but are commonly needed. Copy-paste starters:

### Base Model Mixin

```python
# apps/common/models.py
from django.db import models

class TimestampMixin(models.Model):
    """Add created_at and updated_at to any model."""
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True, db_index=True)

    class Meta:
        abstract = True

class SoftDeleteMixin(models.Model):
    """Add soft delete to any model."""
    deleted = models.BooleanField(default=False, db_index=True)

    def soft_delete(self):
        self.deleted = True
        self.save(update_fields=['deleted'])

    class Meta:
        abstract = True

class BaseModel(TimestampMixin, SoftDeleteMixin):
    """Standard base for all project models."""
    class Meta:
        abstract = True
```

### Custom Exception Handler

```python
# config/exceptions.py
from rest_framework.views import exception_handler

def api_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is not None:
        response.data = {
            'status': 'error',
            'code': response.status_code,
            'message': response.data.get('detail', 'An error occurred'),
            'errors': response.data if 'detail' not in response.data else None,
        }
    return response

# config/settings/base.py
REST_FRAMEWORK['EXCEPTION_HANDLER'] = 'config.exceptions.api_exception_handler'
```

### Pagination Helper

```python
# apps/common/pagination.py
from rest_framework.pagination import PageNumberPagination

class StandardPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100

class SmallPagination(PageNumberPagination):
    page_size = 10
    max_page_size = 50

class LargePagination(PageNumberPagination):
    page_size = 100
    max_page_size = 500
```

---

## Related Documentation

- [Libraries](libraries.md) — Full dependency reference
- [Coding Patterns](coding-patterns.md) — Conventions for using these utilities
- [Application Flows](application-flows.md) — How everything connects
