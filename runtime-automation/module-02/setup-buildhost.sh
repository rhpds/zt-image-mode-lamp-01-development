#!/bin/bash
# Setup script for Module 02
# No additional setup needed - module assumes lamp-dev image from Module 01 exists

set -e

echo "Setting up Module 02..." >> /tmp/progress.log

# Verify lamp-dev image exists from Module 01
if ! su - rhel -c "podman images lamp-dev" | grep -q lamp-dev; then
    echo "WARNING: lamp-dev image not found - Module 01 should be completed first" >> /tmp/progress.log
fi

echo "Module 02 setup complete" >> /tmp/progress.log
exit 0
