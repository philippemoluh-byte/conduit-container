#!/bin/sh
set -e

mkdir -p /usr/share/nginx/html

if [ -z "$(ls -A /usr/share/nginx/html 2>/dev/null)" ]; then
    cp -a /opt/app-dist/. /usr/share/nginx/html/
fi

exec nginx -g 'daemon off;'
