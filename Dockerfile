# Stage 1: Builder - Install dependencies
FROM python:3.12-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements/ requirements/
RUN pip install --no-cache-dir --prefix=/install -r requirements/prod.txt

# Stage 2: Runtime - Minimal production image
FROM python:3.12-slim

WORKDIR /app

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Copy installed Python packages from builder
COPY --from=builder /install /usr/local

# Copy application code
COPY . /app/

# Collect static files
RUN DJANGO_SETTINGS_MODULE=config.settings.production \
    SECRET_KEY=build-placeholder \
    DATABASE_URL=sqlite:///tmp/db.sqlite3 \
    python manage.py collectstatic --noinput 2>/dev/null || true

EXPOSE 8000

CMD ["uvicorn", "config.asgi:application", "--workers", "4", "--host", "0.0.0.0", "--port", "8000"]
