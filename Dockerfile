FROM ubuntu:noble

ENV DEBIAN_FRONTEND noninteractive

# Update the package list and install prerequisites
RUN apt-get update && apt-get install -y \
    software-properties-common \
    lsb-release \
    ca-certificates \
    apt-transport-https \
    wget \
    git \
    curl \
    gnupg2 \
    software-properties-common

# Update package list again and install PHP 8.3 and extensions
RUN apt-get update && apt-get install -y \
    php \
    php-cli \
    php-common \
    php-fpm \
    php-mysql \
    php-zip \
    php-gd \
    php-mbstring \
    php-curl \
    php-xml \
    php-bcmath \
    php-pdo \
    php-sqlite3

# Install composer
RUN apt install -y curl
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install nginx
RUN apt install -y nginx
RUN echo "\
    server {\n\
        listen 80;\n\
        listen [::]:80;\n\
        root /var/www/html/public;\n\
        add_header X-Frame-Options \"SAMEORIGIN\";\n\
        add_header X-Content-Type-Options \"nosniff\";\n\
        index index.php;\n\
        charset utf-8;\n\
        location / {\n\
            try_files \$uri \$uri/ /index.php?\$query_string;\n\
        }\n\
        location = /favicon.ico { access_log off; log_not_found off; }\n\
        location = /robots.txt  { access_log off; log_not_found off; }\n\
        error_page 404 /index.php;\n\
        location ~ \.php$ {\n\
            fastcgi_pass unix:/run/php/php8.3-fpm.sock;\n\
            fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;\n\
            include fastcgi_params;\n\
        }\n\
        location ~ /\.(?!well-known).* {\n\
            deny all;\n\
        }\n\
    }\n" > /etc/nginx/sites-available/default

# Install Fluent Bit
COPY docker/install-fluent-bit.sh /tmp
RUN /tmp/install-fluent-bit.sh

# Copy your Fluent Bit configuration file into the container
RUN mkdir -p /etc/fluent-bit
COPY docker/fluent-bit.conf /etc/fluent-bit

RUN echo "\
    #!/bin/sh\n\
    echo \"Starting services...\"\n\
    service php8.3-fpm start\n\
    nginx -g \"daemon off;\" &\n\
    /opt/fluent-bit/bin/fluent-bit -c /etc/fluent-bit/fluent-bit.conf &\n\
    echo \"Ready.\"\n\
    tail -s 1 /var/log/nginx/*.log -f\n\
    " > /start.sh

COPY . /var/www/html
WORKDIR /var/www/html

RUN touch /var/www/html/storage/logs/laravel.log
RUN chown -R www-data:www-data /var/www/html

RUN composer install

EXPOSE 80

CMD ["sh", "/start.sh"]
