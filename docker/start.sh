#!/bin/sh

echo "Starting services..."

# Start PHP-FPM 8.3
service php8.3-fpm start

# Start Nginx in the foreground
nginx -g "daemon off;" &

# Start Fluent Bit with the specified configuration
/opt/fluent-bit/bin/fluent-bit -c /etc/fluent-bit/fluent-bit.conf &

echo "Ready."

# Tail the Nginx logs indefinitely
tail -s 1 /var/log/nginx/*.log -f
