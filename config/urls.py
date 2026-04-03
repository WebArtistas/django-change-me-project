from django.contrib import admin
from django.urls import include, path

from config.views import health_check

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/v1/', include('config.api_urls')),
    path('api/health/', health_check, name='health-check'),
]
