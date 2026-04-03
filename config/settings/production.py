"""
Production settings for change-me-project.
Security-hardened configuration.
"""

import dj_database_url

from .base import *  # noqa: F401, F403

DEBUG = False

ALLOWED_HOSTS = env.list('ALLOWED_HOSTS')

# Database - PostgreSQL via DATABASE_URL
DATABASES = {
    'default': dj_database_url.config(
        default=env('DATABASE_URL'),
        conn_max_age=600,
        conn_health_checks=True,
    )
}

# Security Settings
SECURE_HSTS_SECONDS = 31536000  # 1 year
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_SSL_REDIRECT = env.bool('SECURE_SSL_REDIRECT', default=True)
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_BROWSER_XSS_FILTER = True
X_FRAME_OPTIONS = 'DENY'

# CSRF Trusted Origins
CSRF_TRUSTED_ORIGINS = env.list('CSRF_TRUSTED_ORIGINS', default=[])

# Static files - WhiteNoise
MIDDLEWARE.insert(
    MIDDLEWARE.index('django.middleware.common.CommonMiddleware'),
    'whitenoise.middleware.WhiteNoiseMiddleware',
)
STORAGES = {
    'staticfiles': {
        'BACKEND': 'whitenoise.storage.CompressedManifestStaticFilesStorage',
    },
}

# Sentry (uncomment and configure when ready)
# import sentry_sdk
# sentry_sdk.init(
#     dsn=env('SENTRY_DSN', default=''),
#     traces_sample_rate=0.1,
#     profiles_sample_rate=0.1,
# )

# Logging
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'WARNING',
    },
    'loggers': {
        'django': {
            'handlers': ['console'],
            'level': 'ERROR',
            'propagate': False,
        },
    },
}
