#!/bin/sh
set -e

mkdir -p /usr/share/nginx/html

# Always refresh served files to avoid stale or default Nginx content.
find /usr/share/nginx/html -mindepth 1 -delete
cp -a /opt/app-dist/. /usr/share/nginx/html/

exec nginx -g 'daemon off;'
