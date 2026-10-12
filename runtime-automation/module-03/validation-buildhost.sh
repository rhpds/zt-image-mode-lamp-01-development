#!/bin/bash
# Validation script for Module 03
# Returns 0 if module objectives are met, non-zero otherwise

set -e

echo "Validating Module 03..." >> /tmp/progress.log

# Check container is running
if ! podman ps | grep -q lamp-dev-container; then
    echo "FAIL: Container not running" >> /tmp/progress.log
    exit 1
fi

# Check application responds
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080)
if [ "$HTTP_CODE" != "200" ]; then
    echo "FAIL: Application not responding (HTTP $HTTP_CODE)" >> /tmp/progress.log
    exit 1
fi

# Check volume mount is working (Apache serves from /app)
if ! podman exec lamp-dev-container grep -q "DocumentRoot /app" /etc/httpd/conf.d/myapp.conf; then
    echo "FAIL: Apache not configured to serve from volume mount" >> /tmp/progress.log
    exit 1
fi

echo "PASS: Module 03 validation successful" >> /tmp/progress.log
exit 0
