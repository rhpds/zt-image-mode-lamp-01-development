#!/bin/bash
# Validation script for Module 01: Prepare Your Development Environment
# Returns 0 if module objectives are met, non-zero otherwise

set -e

echo "Validating Module 01..." >> /tmp/progress.log

# Check if LAMP development directory exists
if [ ! -d /home/rhel/lamp-dev ]; then
    echo "FAIL: LAMP development directory not found" >> /tmp/progress.log
    exit 1
fi

# Check if Containerfile exists
if [ ! -f /home/rhel/lamp-dev/Containerfile ]; then
    echo "FAIL: Containerfile not found" >> /tmp/progress.log
    exit 1
fi

# Check if app directory exists
if [ ! -d /home/rhel/lamp-dev/app ]; then
    echo "FAIL: app directory not found" >> /tmp/progress.log
    exit 1
fi

# Check if lamp-dev image was built
if ! su - rhel -c "podman images lamp-dev" | grep -q lamp-dev; then
    echo "FAIL: lamp-dev image not built" >> /tmp/progress.log
    exit 1
fi

echo "PASS: Module 01 validation successful" >> /tmp/progress.log
exit 0
