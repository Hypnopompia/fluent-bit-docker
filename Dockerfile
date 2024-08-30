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
COPY docker/nginx/default /etc/nginx/sites-available/default

# Install Fluent Bit
COPY docker/fluent-bit/install-fluent-bit.sh /tmp
RUN /tmp/install-fluent-bit.sh

# Copy your Fluent Bit configuration file into the container
RUN mkdir -p /etc/fluent-bit
COPY docker/fluent-bit/fluent-bit.conf /etc/fluent-bit

# Copy the laravel application
COPY . /var/www/html
WORKDIR /var/www/html

RUN touch /var/www/html/storage/logs/laravel.log
RUN chown -R www-data:www-data /var/www/html

RUN composer install

EXPOSE 80

COPY docker/start.sh /start.sh
CMD ["sh", "/start.sh"]
