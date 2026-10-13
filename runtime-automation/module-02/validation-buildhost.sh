#!/bin/bash
# Validation script for Module 02: Build the LAMP Application
# Returns 0 if module objectives are met, non-zero otherwise

set -e

echo "Validating Module 02..." >> /tmp/progress.log

# Check if container is running
if ! su - rhel -c "podman ps" | grep -q lamp-dev-container; then
    echo "FAIL: lamp-dev-container is not running" >> /tmp/progress.log
    exit 1
fi

# Check if MariaDB is running in the container
if ! su - rhel -c "podman exec lamp-dev-container systemctl is-active mariadb" | grep -q "^active$"; then
    echo "FAIL: MariaDB is not running in container" >> /tmp/progress.log
    exit 1
fi

# Check if Apache is running in the container
if ! su - rhel -c "podman exec lamp-dev-container systemctl is-active httpd" | grep -q "^active$"; then
    echo "FAIL: Apache is not running in container" >> /tmp/progress.log
    exit 1
fi

# Check if application responds on port 8080
if ! curl -s http://localhost:8080 > /dev/null; then
    echo "FAIL: Application not responding on port 8080" >> /tmp/progress.log
    exit 1
fi

# Check if application returns database content
if ! curl -s http://localhost:8080 | grep -q "Hello, World"; then
    echo "FAIL: Application not returning expected database content" >> /tmp/progress.log
    exit 1
fi

echo "PASS: Module 02 validation successful" >> /tmp/progress.log
exit 0
