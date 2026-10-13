#!/bin/bash
# Solve script for Module 01: Prepare Your Development Environment
# This runs when the user clicks "Solve"

set -e

echo "Solving Module 01..." >> /tmp/progress.log

# Verify registry authentication
su - rhel -c "podman login registry.redhat.io" >> /tmp/progress.log 2>&1 || true

# Build the development container as rhel user
cd /home/rhel/lamp-dev
su - rhel -c "cd ~/lamp-dev && podman build -t lamp-dev ." >> /tmp/progress.log 2>&1

echo "Module 01 solve complete - LAMP development container built" >> /tmp/progress.log
exit 0
