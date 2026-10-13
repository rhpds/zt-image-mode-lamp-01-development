#!/bin/bash
# Solve script for Module 03: Fix workflow and demonstrate iteration
# This runs when the user clicks "Solve"

set -e

echo "Solving Module 03..." >> /tmp/progress.log

# Fix Apache to serve from volume mount (not /var/www/html)
echo "Fixing Apache DocumentRoot..." >> /tmp/progress.log
su - rhel -c "podman exec lamp-dev-container sed -i 's|DocumentRoot /var/www/html|DocumentRoot /app|' /etc/httpd/conf.d/myapp.conf" >> /tmp/progress.log 2>&1
su - rhel -c "podman exec lamp-dev-container sed -i 's|<Directory /var/www/html>|<Directory /app>|' /etc/httpd/conf.d/myapp.conf" >> /tmp/progress.log 2>&1
su - rhel -c "podman exec lamp-dev-container systemctl reload httpd" >> /tmp/progress.log 2>&1

sleep 1

# Add new database record
echo "Adding database record..." >> /tmp/progress.log
su - rhel -c "podman exec lamp-dev-container mariadb -u hellouser -pSecurePassword hellodb -e \"INSERT INTO greetings (message) VALUES ('Iteration is instant');\"" >> /tmp/progress.log 2>&1

# Add yellow box to index.php (on host, will appear via volume mount)
echo "Adding yellow box to application..." >> /tmp/progress.log
cat >> /home/rhel/lamp-dev/app/index.php << 'EOF'

<!-- Modified during development -->
<div style="background: #fff3cd; padding: 10px; margin-top: 20px; border-radius: 5px;">
    <strong>Note:</strong> This application uses volume mounts for development.
    Changes to this file appear instantly without rebuilding the container.
</div>
EOF
chown rhel:rhel /home/rhel/lamp-dev/app/index.php

echo "Module 03 solve complete" >> /tmp/progress.log
exit 0
