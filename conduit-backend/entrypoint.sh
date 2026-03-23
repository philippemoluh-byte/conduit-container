#!/bin/sh
set -e

# Apply migrations
python manage.py migrate --noinput

# Collect static files (optionally, if needed)
# python manage.py collectstatic --noinput

# Start Gunicorn with uwsgi protocol
# Daher: conduit.wsgi:application is the path zum WSGI-App-Object
exec gunicorn \
    --bind 0.0.0.0:8000 \
    --workers 4 \
    --worker-class sync \
    --max-requests 1000 \
    --max-requests-jitter 50 \
    --timeout 30 \
    --access-logfile - \
    --error-logfile - \
    --log-level info \
    conduit.wsgi:application
