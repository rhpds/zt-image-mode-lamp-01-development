#!/bin/bash
set -x
USER=rhel

echo "Adding wheel" > /root/post-run.log
usermod -aG wheel rhel

echo "Setup build host for LAMP development lab" > /tmp/progress.log
chmod 666 /tmp/progress.log

# Base images for the lab
UBI_BASE=registry.redhat.io/ubi10/ubi-init:latest
BOOTC_BASE=registry.redhat.io/rhel10/rhel-bootc:10.1

# Set up libvirt and name resolution for nested virtualization
echo "Setting up libvirt for nested virtualization..." >> /tmp/progress.log
systemctl enable --now libvirtd
sed -i 's/hosts:\s\+ files/& libvirt libvirt_guest/' /etc/nsswitch.conf

# Set up registry authentication for root user
echo "Configuring registry authentication..." >> /tmp/progress.log
mkdir -p ~/.config/containers
cat <<EOF> ~/.config/containers/auth.json
{
    "auths": {
      "registry.redhat.io": {
        "auth": "${REGISTRY_PULL_TOKEN}"
      }
    }
  }
EOF

# Set up registry authentication for rhel user
mkdir -p /home/rhel/.config/containers
cat <<EOF> /home/rhel/.config/containers/auth.json
{
    "auths": {
      "registry.redhat.io": {
        "auth": "${REGISTRY_PULL_TOKEN}"
      }
    }
  }
EOF
chown -R rhel:rhel /home/rhel/.config

# Pull base image so it's available for rhel user
echo "Pulling UBI base image..." >> /tmp/progress.log
su - rhel -c "podman pull registry.redhat.io/ubi10/ubi-init:latest" >> /tmp/progress.log 2>&1

# Create directory structure for LAMP development
echo "Creating LAMP development directory structure..." >> /tmp/progress.log
mkdir -p /home/rhel/lamp-dev/app
chown -R rhel:rhel /home/rhel/lamp-dev

# Create template Containerfile for development
echo "Creating template Containerfile..." >> /tmp/progress.log
cat <<'EOF' > /home/rhel/lamp-dev/Containerfile
# Development LAMP Stack Container
# Uses UBI for development with volume mounts
FROM registry.redhat.io/ubi10/ubi-init:latest

# Install LAMP stack
RUN dnf install -y mariadb-server httpd php php-mysqlnd && \
    dnf clean all

# Enable services
RUN systemctl enable mariadb httpd

# Expose Apache port
EXPOSE 80

# Use systemd as init
CMD ["/sbin/init"]
EOF
chown rhel:rhel /home/rhel/lamp-dev/Containerfile

# Create example database setup script
echo "Creating example database setup script..." >> /tmp/progress.log
cat <<'EOF' > /home/rhel/lamp-dev/app/db-setup.sql.example
-- Example database setup
-- This creates a simple database with one table

CREATE DATABASE IF NOT EXISTS hellodb;
CREATE USER IF NOT EXISTS 'hellouser'@'localhost' IDENTIFIED BY 'SecurePassword';
GRANT ALL PRIVILEGES ON hellodb.* TO 'hellouser'@'localhost';
FLUSH PRIVILEGES;

USE hellodb;

CREATE TABLE IF NOT EXISTS greetings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    message VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO greetings (message) VALUES ('Hello, World!');
INSERT INTO greetings (message) VALUES ('Welcome to LAMP with Image Mode!');
EOF
chown rhel:rhel /home/rhel/lamp-dev/app/db-setup.sql.example

# Create example PHP application
echo "Creating example PHP application..." >> /tmp/progress.log
cat <<'EOF' > /home/rhel/lamp-dev/app/index.php.example
<!DOCTYPE html>
<html>
<head>
    <title>LAMP Stack with Image Mode</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #c00; }
        .message { background: #f0f0f0; padding: 20px; margin: 10px 0; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>LAMP Application - Development Container</h1>

    <?php
    // Database connection
    $host = '127.0.0.1';
    $db   = 'hellodb';
    $user = 'hellouser';
    $pass = 'SecurePassword';
    $charset = 'utf8mb4';

    $dsn = "mysql:host=$host;dbname=$db;charset=$charset";
    $options = [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ];

    try {
        $pdo = new PDO($dsn, $user, $pass, $options);
        $stmt = $pdo->query('SELECT message, created_at FROM greetings ORDER BY created_at DESC');

        echo "<h2>Messages from Database:</h2>";
        while ($row = $stmt->fetch()) {
            echo "<div class='message'>";
            echo "<strong>" . htmlspecialchars($row['message']) . "</strong><br>";
            echo "<small>Created: " . htmlspecialchars($row['created_at']) . "</small>";
            echo "</div>";
        }
    } catch (\PDOException $e) {
        echo "<p style='color: red;'>Database Error: Could not connect to database.</p>";
        echo "<p><small>Check that MariaDB is running and initialized with db-setup.sql</small></p>";
    }
    ?>

    <hr>
    <p><small>Running on: <?php echo gethostname(); ?></small></p>
</body>
</html>
EOF
chown rhel:rhel /home/rhel/lamp-dev/app/index.php.example

# Create example Apache configuration
echo "Creating example Apache configuration..." >> /tmp/progress.log
cat <<'EOF' > /home/rhel/lamp-dev/app/myapp.conf.example
# Apache VirtualHost configuration for LAMP application
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/httpd/error_log
    CustomLog /var/log/httpd/access_log combined
</VirtualHost>
EOF
chown rhel:rhel /home/rhel/lamp-dev/app/myapp.conf.example

# Generate SSH keys for VM access (will be used in Lab 2, but create now)
echo "Generating SSH keys for VM access..." >> /tmp/progress.log
if [ ! -f /home/rhel/.ssh/id_ed25519 ]; then
    sudo -u rhel ssh-keygen -t ed25519 -f /home/rhel/.ssh/id_ed25519 -N '' -C "LAMP Lab SSH Key"
fi

# Create a helpful README
cat <<'EOF' > /home/rhel/lamp-dev/README.md
# LAMP Development Lab

## Directory Structure

```
~/lamp-dev/
├── Containerfile           # Container definition
└── app/                    # Application files (mounted as volume)
    ├── db-setup.sql        # Database initialization
    ├── index.php           # PHP application
    └── myapp.conf          # Apache configuration
```

## Template Files

Example files are provided with `.example` extension:
- `app/db-setup.sql.example`
- `app/index.php.example`
- `app/myapp.conf.example`

You can copy these or create your own from scratch during the lab.

## Quick Start (CLI)

1. Authenticate to Red Hat registry:
   ```bash
   podman login registry.redhat.io
   ```

2. Build the development image:
   ```bash
   cd ~/lamp-dev
   podman build -f Containerfile -t lamp-dev-image .
   ```

3. Run the container with volume mount:
   ```bash
   podman run -d --name lamp-dev \
     -p 8080:80 \
     -v ~/lamp-dev/app:/app:z \
     lamp-dev-image
   ```

4. Access the container:
   ```bash
   podman exec -it lamp-dev /bin/bash
   ```

5. Initialize MariaDB (inside container):
   ```bash
   systemctl start mariadb
   mariadb -u root < /app/db-setup.sql
   ```

6. Deploy application files (inside container):
   ```bash
   cp /app/index.php /var/www/html/
   cp /app/myapp.conf /etc/httpd/conf.d/
   systemctl start httpd
   ```

7. Test:
   ```bash
   curl http://localhost:8080
   ```
EOF
chown rhel:rhel /home/rhel/lamp-dev/README.md

echo "Setup complete!" >> /tmp/progress.log
echo "LAMP development environment ready at /home/rhel/lamp-dev" >> /tmp/progress.log
