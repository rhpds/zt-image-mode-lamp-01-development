#!/bin/bash
# Validation script for Module 03
# Returns 0 if module objectives are met, non-zero otherwise

set -e

echo "Validating Module 03..." >> /tmp/progress.log

# Check container is running
if ! su - rhel -c "podman ps" | grep -q lamp-dev-container; then
    echo "FAIL: Container not running" >> /tmp/progress.log
    exit 1
fi

# Check application responds
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080)
if [ "$HTTP_CODE" != "200" ]; then
    echo "FAIL: Application not responding (HTTP $HTTP_CODE)" >> /tmp/progress.log
    exit 1
fi

# Check volume mount workflow fix (Apache serves from /app)
if ! su - rhel -c "podman exec lamp-dev-container grep -q 'DocumentRoot /app' /etc/httpd/conf.d/myapp.conf"; then
    echo "FAIL: Apache not configured to serve from volume mount" >> /tmp/progress.log
    exit 1
fi

# Check H1 heading was changed
if ! curl -s http://localhost:8080 | grep -q "My LAMP Application"; then
    echo "FAIL: H1 heading not changed to 'My LAMP Application'" >> /tmp/progress.log
    exit 1
fi

# Check database has 4 rows (including 'Iteration is instant')
ROW_COUNT=$(su - rhel -c "podman exec lamp-dev-container mariadb -u hellouser -pSecurePassword hellodb -se 'SELECT COUNT(*) FROM greetings;'")
if [ "$ROW_COUNT" != "4" ]; then
    echo "FAIL: Database should have 4 rows, found $ROW_COUNT" >> /tmp/progress.log
    exit 1
fi

# Check yellow box appears in the page
if ! curl -s http://localhost:8080 | grep -q "volume mounts for development"; then
    echo "FAIL: Yellow box content not found in page" >> /tmp/progress.log
    exit 1
fi

echo "PASS: Module 03 validation successful" >> /tmp/progress.log
exit 0
