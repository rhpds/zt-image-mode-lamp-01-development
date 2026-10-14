#!/bin/bash
# Solve script for Module 01: Prepare Your Development Environment
# This runs when the user clicks "Solve"

set -e

echo "Solving Module 01..." >> /tmp/progress.log
echo "Timestamp: $(date)" >> /tmp/progress.log

# Verify registry authentication
echo "Verifying registry authentication..." >> /tmp/progress.log
su - rhel -c "podman login registry.redhat.io" >> /tmp/progress.log 2>&1 || true
echo "Registry authentication verified" >> /tmp/progress.log

# Build the development container as rhel user
echo "Building lamp-dev container..." >> /tmp/progress.log
cd /home/rhel/lamp-dev
su - rhel -c "cd ~/lamp-dev && podman build -t lamp-dev ." >> /tmp/progress.log 2>&1
echo "Container built successfully" >> /tmp/progress.log

# Verify image was created
if su - rhel -c "podman images lamp-dev" | grep -q lamp-dev; then
    echo "Image verification: SUCCESS" >> /tmp/progress.log
else
    echo "Image verification: FAILED" >> /tmp/progress.log
    exit 1
fi

echo "Module 01 solve complete - LAMP development container built" >> /tmp/progress.log
exit 0
