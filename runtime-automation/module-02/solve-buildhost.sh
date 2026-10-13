#!/bin/bash
# Solve script for Module 02: Build the LAMP Application
# This completes the LAMP configuration automatically

set -e

echo "Solving Module 02..." >> /tmp/progress.log

# Check if lamp-dev image exists (from Module 01)
if ! su - rhel -c "podman images lamp-dev" | grep -q lamp-dev; then
    echo "ERROR: lamp-dev image must be built from Module 01" >> /tmp/progress.log
    exit 1
fi

# Stop and remove existing container if it exists
su - rhel -c "podman stop lamp-dev-container 2>/dev/null || true" >> /tmp/progress.log
su - rhel -c "podman rm lamp-dev-container 2>/dev/null || true" >> /tmp/progress.log

# Run the container with volume mount
su - rhel -c "podman run -d --name lamp-dev-container -p 8080:80 -v ~/lamp-dev/app:/app:z lamp-dev" >> /tmp/progress.log

# Wait for container to be ready
sleep 3

# Start MariaDB
su - rhel -c "podman exec lamp-dev-container systemctl start mariadb" >> /tmp/progress.log
sleep 2

# Create database setup script on host
cat > /home/rhel/lamp-dev/app/db-setup.sql << 'EOF'
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
INSERT INTO greetings (message) VALUES ('Welcome to LAMP development!');
INSERT INTO greetings (message) VALUES ('Volume mounts make iteration fast.');
EOF
chown rhel:rhel /home/rhel/lamp-dev/app/db-setup.sql

# Initialize database (file is available at /app inside container via volume mount)
su - rhel -c "podman exec lamp-dev-container mariadb -u root < /app/db-setup.sql" >> /tmp/progress.log

# Create PHP application on host
cat > /home/rhel/lamp-dev/app/index.php << 'PHPEOF'
<!DOCTYPE html>
<html>
<head>
    <title>LAMP Application - Development Mode</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
            background-color: #f5f5f5;
        }
        h1 { color: #c00; }
        .message {
            background: white;
            padding: 20px;
            margin: 10px 0;
            border-radius: 5px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .info {
            background: #e3f2fd;
            padding: 10px;
            border-radius: 5px;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <h1>LAMP Application - Development Mode</h1>

    <h2>Messages from Database:</h2>
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

        while ($row = $stmt->fetch()) {
            echo "<div class='message'><strong>" . htmlspecialchars($row['message']) . "</strong><br>";
            echo "<small>Created: " . htmlspecialchars($row['created_at']) . "</small></div>";
        }
    } catch (\PDOException $e) {
        echo "<p style='color: red;'>Database Error: Could not connect.</p>";
    }
    ?>

    <div class='info'>
        <strong>Environment:</strong> Development (volume mounts)<br>
        <strong>Workflow:</strong> Mutable (edit files on host, changes appear instantly)<br>
        <strong>Host:</strong> <?php echo gethostname(); ?>
    </div>
</body>
</html>
PHPEOF
chown rhel:rhel /home/rhel/lamp-dev/app/index.php

# Create Apache config on host to serve directly from volume mount
cat > /home/rhel/lamp-dev/app/myapp.conf << 'EOF'
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
chown rhel:rhel /home/rhel/lamp-dev/app/myapp.conf

# Deploy Apache config (inside container)
su - rhel -c "podman exec lamp-dev-container cp /app/myapp.conf /etc/httpd/conf.d/" >> /tmp/progress.log

# Configure SELinux (may not be available in container - that's fine)
su - rhel -c "podman exec lamp-dev-container bash -c 'setsebool -P httpd_can_network_connect_db on 2>/dev/null || true'" >> /tmp/progress.log

# Start Apache
su - rhel -c "podman exec lamp-dev-container systemctl start httpd" >> /tmp/progress.log

# Wait for Apache to be ready
sleep 2

echo "Module 02 solve completed successfully" >> /tmp/progress.log
exit 0
