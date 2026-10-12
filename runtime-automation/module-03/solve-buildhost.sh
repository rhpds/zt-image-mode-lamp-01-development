#!/bin/bash
# Solve script for Module 03
# This runs when the user clicks "Solve"

set -e

echo "Solving Module 03..." >> /tmp/progress.log

# Module 03 is about testing and iteration
# The main actions were already done in Module 02
# This solve would demonstrate the volume mount workflow

# Ensure container is running
if ! podman ps | grep -q lamp-dev-container; then
    echo "Starting container..." >> /tmp/progress.log
    podman run -d \
      --name lamp-dev-container \
      -p 8080:80 \
      -v ~/lamp-dev/app:/app:z \
      lamp-dev >> /tmp/progress.log 2>&1
fi

# Fix Apache to serve from volume mount
podman exec lamp-dev-container bash -c "cat > /etc/httpd/conf.d/myapp.conf << 'EOF'
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /app

    <Directory /app>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/httpd/error_log
    CustomLog /var/log/httpd/access_log combined
</VirtualHost>
EOF
systemctl restart httpd" >> /tmp/progress.log 2>&1

echo "Module 03 solve complete" >> /tmp/progress.log
exit 0
