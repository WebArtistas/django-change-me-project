# User Flows (Developer Workflow)

Step-by-step workflows for common tasks when building on this template.

---

## Flow 1: Clone and Rename (First Time Setup)

```
1. Clone the template
   git clone https://github.com/WebArtistas/django-change-me-project.git my-api
   cd my-api

2. Rename everything to your project name
   ./rename-project.sh my-api
   ↳ Replaces in all files:
     change-me-project → my-api          (kebab-case)
     change_me_project → my_api          (snake_case)
     ChangeMeProject   → MyApi           (PascalCase)
   ↳ Excludes: .git/, venv/, __pycache__/

3. Fresh git history
   rm -rf .git && git init && git add -A && git commit -m "feat: initial project"

4. Create virtual environment
   python3 -m venv venv
   source venv/bin/activate

5. Install dependencies
   pip install -r requirements/dev.txt

6. Configure environment
   cp .env.example .env
   # Edit .env with your SECRET_KEY

7. Run migrations and start
   python manage.py migrate
   python manage.py runserver

8. Verify
   curl http://127.0.0.1:8000/api/health/
   → {"status": "ok", "project": "my-api"}
```

---

## Flow 2: Add a New Django App

```
1. Create the app inside apps/ directory
   python manage.py startapp myapp apps/myapp

2. Register in INSTALLED_APPS
   # config/settings/base.py
   INSTALLED_APPS = [
       ...
       'apps.myapp',
   ]

3. Create model
   # apps/myapp/models.py

4. Create serializer
   # apps/myapp/serializers.py

5. Create viewset
   # apps/myapp/views.py

6. Create URL routing
   # apps/myapp/urls.py
   from rest_framework.routers import DefaultRouter
   from .views import MyModelViewSet

   router = DefaultRouter()
   router.register('items', MyModelViewSet, basename='item')
   urlpatterns = router.urls

7. Connect to main API router
   # config/api_urls.py
   from django.urls import path, include
   urlpatterns = [
       path('myapp/', include('apps.myapp.urls')),
   ]

8. Create and run migrations
   python manage.py makemigrations myapp
   python manage.py migrate

9. Verify
   curl http://127.0.0.1:8000/api/v1/myapp/items/
```

**Result:** `GET /api/v1/myapp/items/` returns paginated list (20 items/page).

---

## Flow 3: Add Authentication (JWT)

```
1. Install packages
   pip install djangorestframework-simplejwt dj-rest-auth django-allauth

2. Add to base.txt
   echo "djangorestframework-simplejwt>=5.3,<6.0" >> requirements/base.txt
   echo "dj-rest-auth>=7.0,<8.0" >> requirements/base.txt
   echo "django-allauth>=65.0,<66.0" >> requirements/base.txt

3. Update settings
   # config/settings/base.py
   INSTALLED_APPS += [
       'django.contrib.sites',
       'rest_framework.authtoken',
       'allauth',
       'allauth.account',
       'dj_rest_auth',
       'dj_rest_auth.registration',
   ]
   SITE_ID = 1
   MIDDLEWARE += ['allauth.account.middleware.AccountMiddleware']

   REST_FRAMEWORK['DEFAULT_AUTHENTICATION_CLASSES'] = [
       'rest_framework_simplejwt.authentication.JWTAuthentication',
   ]

4. Add auth URLs
   # config/urls.py
   urlpatterns += [
       path('api/v1/auth/', include('dj_rest_auth.urls')),
       path('api/v1/auth/register/', include('dj_rest_auth.registration.urls')),
   ]

5. Migrate
   python manage.py migrate

6. Test
   # Register
   curl -X POST http://127.0.0.1:8000/api/v1/auth/register/ \
     -H "Content-Type: application/json" \
     -d '{"email":"test@test.com","password1":"testpass123!","password2":"testpass123!"}'

   # Login → get JWT token
   curl -X POST http://127.0.0.1:8000/api/v1/auth/login/ \
     -H "Content-Type: application/json" \
     -d '{"email":"test@test.com","password":"testpass123!"}'

   # Use token
   curl http://127.0.0.1:8000/api/v1/myapp/items/ \
     -H "Authorization: Bearer <access_token>"
```

---

## Flow 4: Add Background Tasks (Celery)

```
1. Install packages
   pip install celery django-celery-beat redis

2. Create Celery config
   # config/celery.py
   import os
   from celery import Celery

   os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
   app = Celery('config')
   app.config_from_object('django.conf:settings', namespace='CELERY')
   app.autodiscover_tasks()

3. Import in __init__.py
   # config/__init__.py
   from .celery import app as celery_app
   __all__ = ('celery_app',)

4. Add settings
   # config/settings/base.py
   INSTALLED_APPS += ['django_celery_beat']
   CELERY_BROKER_URL = env('REDIS_URL', default='redis://localhost:6379/0')
   CELERY_RESULT_BACKEND = CELERY_BROKER_URL

5. Create a task
   # apps/myapp/tasks.py
   from config.celery import app

   @app.task
   def send_welcome_email(user_id):
       # task logic here
       pass

6. Call the task
   from apps.myapp.tasks import send_welcome_email
   send_welcome_email.delay(user.id)  # runs async in worker

7. Run worker
   celery -A config worker -l DEBUG
   celery -A config beat -l DEBUG     # for scheduled tasks
```

---

## Flow 5: Connect Angular Frontend

```
1. Set CORS in .env
   CORS_ALLOWED_ORIGINS=http://localhost:4200

2. Start Django
   python manage.py runserver

3. In Angular, configure API base URL
   // environment.ts
   export const environment = {
     apiUrl: 'http://127.0.0.1:8000/api/v1'
   };

4. Make requests with HttpClient
   // Angular service
   this.http.get(`${environment.apiUrl}/myapp/items/`, {
     headers: { Authorization: `Bearer ${token}` }
   })

5. Pre-configured CORS headers allow:
   - Authorization (for JWT)
   - Content-Type (for JSON)
   - X-CSRFToken (for CSRF)
   - X-Current-App (for multi-app scoping)
```

---

## Flow 6: Deploy to Production

```
1. Set environment variables
   DATABASE_URL=postgres://user:pass@host:5432/dbname
   SECRET_KEY=<strong-random-key>
   ALLOWED_HOSTS=api.yourdomain.com
   CORS_ALLOWED_ORIGINS=https://yourdomain.com
   CSRF_TRUSTED_ORIGINS=https://yourdomain.com
   SECURE_SSL_REDIRECT=True
   SENTRY_DSN=https://...@sentry.io/...

2. Check deployment readiness
   make check-deploy
   ↳ Validates: HSTS, SSL redirect, secure cookies, CSRF, XSS filter

3. Build Docker image
   docker compose build

4. Run migrations against production DB
   DJANGO_SETTINGS_MODULE=config.settings.production \
   python manage.py migrate

5. Collect static files
   DJANGO_SETTINGS_MODULE=config.settings.production \
   python manage.py collectstatic --noinput

6. Deploy
   # Docker
   docker compose -f docker-compose.yml up -d

   # Or Fly.io
   fly deploy
```

---

## Flow 7: Run Tests

```
1. Write tests
   # apps/myapp/tests.py
   from django.test import TestCase
   from .models import MyModel

   class MyModelTest(TestCase):
       def test_creation(self):
           obj = MyModel.objects.create(name="test")
           self.assertEqual(obj.name, "test")

2. Run tests
   make test
   # equivalent to:
   python manage.py test --settings=config.settings.testing

3. Testing settings auto-applied:
   - In-memory SQLite (fast, no disk I/O)
   - MD5 password hasher (fast, not secure — test-only)
   - No throttling
   - Silent logging
```

---

## Flow 8: Add a Custom Management Command

```
1. Create command directory
   mkdir -p apps/myapp/management/commands

2. Create command file
   # apps/myapp/management/commands/seed_data.py
   from django.core.management.base import BaseCommand
   from apps.myapp.models import MyModel

   class Command(BaseCommand):
       help = 'Seeds the database with initial data'

       def add_arguments(self, parser):
           parser.add_argument('--count', type=int, default=10)

       def handle(self, *args, **options):
           count = options['count']
           for i in range(count):
               MyModel.objects.create(name=f"Item {i+1}")
           self.stdout.write(self.style.SUCCESS(f"Created {count} items"))

3. Run it
   python manage.py seed_data --count=50
```

---

## Makefile Quick Reference

| What You Want | Command |
|---------------|---------|
| Start dev server | `make run` |
| Create migrations | `make makemigrations` |
| Apply migrations | `make migrate` |
| Run tests | `make test` |
| Django shell | `make shell` |
| Create admin user | `make superuser` |
| Start Docker | `make docker-up` |
| Stop Docker | `make docker-down` |
| Build Docker | `make docker-build` |
| Clean caches | `make clean` |
| Check prod settings | `make check-deploy` |

---

## Related Documentation

- [Application Flows](application-flows.md) — How requests move through the stack
- [Coding Patterns](coding-patterns.md) — Code conventions and patterns
- [Libraries](libraries.md) — What each dependency does
