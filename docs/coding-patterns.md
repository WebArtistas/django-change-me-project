# Coding Patterns & Conventions

Patterns and rules to follow when building on this template. These conventions are designed to keep every project that starts from this template consistent and maintainable.

---

## Project Layout Rules

### Apps go in `apps/`

All Django apps live inside the `apps/` directory — never at root level.

```bash
# CORRECT
python manage.py startapp users apps/users

# WRONG
python manage.py startapp users
```

Register with the `apps.` prefix:

```python
INSTALLED_APPS = [
    ...
    'apps.users',     # correct
    # 'users',        # wrong — breaks when apps/ has __init__.py
]
```

### Config stays in `config/`

The `config/` directory holds all project-level configuration. This name was chosen deliberately so it never needs renaming — unlike the default Django pattern of naming the project directory after the project.

```
config/
  settings/
    base.py           # shared settings
    development.py    # local overrides
    production.py     # production hardening
    testing.py        # test optimization
  urls.py             # root URL routing
  api_urls.py         # API v1 routes
  views.py            # project-level views (health check)
  wsgi.py / asgi.py   # server entry points
```

### URL versioning

All API routes live under `/api/v1/`:

```python
# config/urls.py — already configured
path('api/v1/', include('config.api_urls')),

# config/api_urls.py — add your app routes here
urlpatterns = [
    path('users/', include('apps.users.urls')),
    path('tasks/', include('apps.tasks.urls')),
]
```

When breaking changes are needed, add `/api/v2/` alongside v1.

---

## Model Patterns

### Standard model structure

```python
from django.db import models
from django.conf import settings


class MyModel(models.Model):
    """Brief description of what this model represents."""

    # Relationships first
    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='my_models'
    )

    # Core fields
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    status = models.CharField(
        max_length=20,
        choices=[('draft', 'Draft'), ('published', 'Published')],
        default='draft'
    )

    # Metadata fields last
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['owner', 'status']),
        ]

    def __str__(self):
        return self.name
```

### Rules

- Always add `created_at` and `updated_at` timestamps
- Always add `__str__` method
- Always add `related_name` on ForeignKey/M2M fields
- Use `settings.AUTH_USER_MODEL` instead of importing User directly
- Add database indexes for fields used in filters and ordering
- Use `choices` for fields with a fixed set of values
- Field order: relationships → core fields → metadata

### Soft delete pattern

If you need soft deletes, add a `deleted` boolean:

```python
class MyModel(models.Model):
    deleted = models.BooleanField(default=False)

    def soft_delete(self):
        self.deleted = True
        self.save(update_fields=['deleted'])

    class Meta:
        # Default manager excludes deleted
        pass

# Always filter:
MyModel.objects.filter(deleted=False)
```

---

## Serializer Patterns

### Standard serializer

```python
from rest_framework import serializers
from .models import MyModel


class MyModelSerializer(serializers.ModelSerializer):
    """Serializer for MyModel CRUD operations."""

    class Meta:
        model = MyModel
        fields = ['id', 'name', 'description', 'status', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']
```

### Computed fields

```python
class MyModelSerializer(serializers.ModelSerializer):
    owner_name = serializers.SerializerMethodField()

    class Meta:
        model = MyModel
        fields = ['id', 'name', 'owner_name']

    def get_owner_name(self, obj):
        return obj.owner.get_full_name()
```

### Separate serializers for different actions

```python
# List view — minimal fields
class MyModelListSerializer(serializers.ModelSerializer):
    class Meta:
        model = MyModel
        fields = ['id', 'name', 'status']

# Detail view — all fields
class MyModelDetailSerializer(serializers.ModelSerializer):
    class Meta:
        model = MyModel
        fields = '__all__'

# Create — only writable fields
class MyModelCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = MyModel
        fields = ['name', 'description']
```

Use `get_serializer_class()` in the viewset to switch.

---

## ViewSet Patterns

### Standard CRUD viewset

```python
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from .models import MyModel
from .serializers import MyModelSerializer


class MyModelViewSet(viewsets.ModelViewSet):
    """CRUD API for MyModel."""

    serializer_class = MyModelSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # Always scope to current user
        return MyModel.objects.filter(
            owner=self.request.user,
            deleted=False
        )

    def perform_create(self, serializer):
        # Auto-set owner on creation
        serializer.save(owner=self.request.user)
```

### Custom actions

```python
from rest_framework.decorators import action
from rest_framework.response import Response


class MyModelViewSet(viewsets.ModelViewSet):
    ...

    @action(detail=True, methods=['post'])
    def publish(self, request, pk=None):
        """POST /api/v1/myapp/items/{id}/publish/"""
        obj = self.get_object()
        obj.status = 'published'
        obj.save(update_fields=['status'])
        return Response({'status': 'published'})

    @action(detail=False, methods=['get'])
    def stats(self, request):
        """GET /api/v1/myapp/items/stats/"""
        count = self.get_queryset().count()
        return Response({'total': count})
```

### Switching serializers per action

```python
class MyModelViewSet(viewsets.ModelViewSet):
    def get_serializer_class(self):
        if self.action == 'list':
            return MyModelListSerializer
        if self.action == 'create':
            return MyModelCreateSerializer
        return MyModelDetailSerializer
```

---

## URL Routing Patterns

### App-level routing with DRF Router

```python
# apps/myapp/urls.py
from rest_framework.routers import DefaultRouter
from .views import MyModelViewSet

router = DefaultRouter()
router.register('items', MyModelViewSet, basename='item')

urlpatterns = router.urls
```

### Connecting to the main API

```python
# config/api_urls.py
from django.urls import path, include

urlpatterns = [
    path('myapp/', include('apps.myapp.urls')),
    # Results in: /api/v1/myapp/items/
]
```

### URL naming convention

| Pattern | Example |
|---------|---------|
| App prefix | `/api/v1/myapp/` |
| Resource list | `/api/v1/myapp/items/` |
| Resource detail | `/api/v1/myapp/items/{id}/` |
| Custom action | `/api/v1/myapp/items/{id}/publish/` |
| Collection action | `/api/v1/myapp/items/stats/` |

---

## Settings Patterns

### Adding new settings

Add shared settings to `base.py`, override per environment:

```python
# base.py — default value
MY_FEATURE_ENABLED = env.bool('MY_FEATURE_ENABLED', default=False)
API_PAGE_SIZE = env.int('API_PAGE_SIZE', default=20)

# development.py — override for local
MY_FEATURE_ENABLED = True

# production.py — use env var
# (inherits from base, reads from .env)
```

### Adding new environment variables

1. Add to `config/settings/base.py` with a safe default
2. Add to `.env.example` with a placeholder
3. Document in `README.md` environment variables table

---

## Permission Patterns

### Default: all endpoints require authentication

Configured in `base.py`:

```python
REST_FRAMEWORK = {
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}
```

### Override per viewset

```python
from rest_framework.permissions import IsAuthenticated, IsAdminUser, AllowAny

class PublicViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [AllowAny]  # public read-only

class AdminViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminUser]  # staff only
```

### Per-action permissions

```python
class MyViewSet(viewsets.ModelViewSet):
    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [AllowAny()]
        return [IsAuthenticated()]
```

---

## Error Handling Patterns

### REST API response format

Keep responses consistent:

```python
# Success
return Response({
    'status': 'ok',
    'data': serializer.data
})

# Error
return Response({
    'status': 'error',
    'message': 'Resource not found'
}, status=status.HTTP_404_NOT_FOUND)

# Validation error (DRF handles automatically)
# 400 Bad Request with field-level errors
```

### Custom exception handler (optional)

```python
# config/exception_handler.py
from rest_framework.views import exception_handler

def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is not None:
        response.data = {
            'status': 'error',
            'message': response.data.get('detail', str(response.data)),
            'errors': response.data if isinstance(response.data, dict) else None,
        }
    return response

# base.py
REST_FRAMEWORK['EXCEPTION_HANDLER'] = 'config.exception_handler.custom_exception_handler'
```

---

## Testing Patterns

### Test file location

```
apps/myapp/
  tests/
    __init__.py
    test_models.py
    test_views.py
    test_serializers.py
```

Or for small apps, a single `tests.py` file is fine.

### Test structure

```python
from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APITestCase, APIClient
from .models import MyModel

User = get_user_model()


class MyModelTest(TestCase):
    """Unit tests for MyModel."""

    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            password='testpass123'
        )

    def test_creation(self):
        obj = MyModel.objects.create(name='Test', owner=self.user)
        self.assertEqual(str(obj), 'Test')


class MyModelAPITest(APITestCase):
    """Integration tests for MyModel API."""

    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            password='testpass123'
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)

    def test_list_returns_only_own_items(self):
        MyModel.objects.create(name='Mine', owner=self.user)
        response = self.client.get('/api/v1/myapp/items/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data['results']), 1)
```

### Run tests

```bash
make test
# or
python manage.py test --settings=config.settings.testing
```

---

## Naming Conventions

| Item | Convention | Example |
|------|-----------|---------|
| Django apps | lowercase, plural | `apps/users`, `apps/tasks` |
| Model classes | PascalCase, singular | `Task`, `UserProfile` |
| Serializer classes | `{Model}Serializer` | `TaskSerializer` |
| ViewSet classes | `{Model}ViewSet` | `TaskViewSet` |
| URL paths | kebab-case, plural | `api/v1/user-profiles/` |
| Task functions | snake_case, verb-first | `send_welcome_email` |
| Test classes | `{Model}Test` / `{Model}APITest` | `TaskTest`, `TaskAPITest` |
| Settings variables | UPPER_SNAKE_CASE | `API_PAGE_SIZE` |
| Env variables | UPPER_SNAKE_CASE | `DATABASE_URL` |

---

## File Template Checklist

When creating a new app, ensure you have:

```
apps/newapp/
  __init__.py          ✓ (auto-created)
  models.py            ✓ models with timestamps, __str__, Meta
  serializers.py       ✓ ModelSerializer with explicit fields
  views.py             ✓ ViewSet with permissions and get_queryset()
  urls.py              ✓ DefaultRouter registration
  admin.py             ✓ ModelAdmin for each model
  tests.py             ✓ at least model + API tests
```

Then wire up:
- [ ] `INSTALLED_APPS` in `config/settings/base.py`
- [ ] URL include in `config/api_urls.py`
- [ ] Migrations: `makemigrations` + `migrate`

---

## Related Documentation

- [Application Flows](application-flows.md) — Request lifecycle
- [User Flows](user-flows.md) — Step-by-step developer workflows
- [Libraries](libraries.md) — Dependency reference
