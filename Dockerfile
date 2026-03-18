# ---------- Stage 1: Build ----------
FROM php:8.2-fpm AS builder

WORKDIR /var/www

# Install dependencies
RUN apt-get update && apt-get install -y \
    git unzip curl libzip-dev zip \
    && docker-php-ext-install pdo pdo_mysql zip

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy project
COPY . .

# Install Laravel dependencies
RUN composer install --no-dev --optimize-autoloader

# Generate app key (IMPORTANT)
RUN php artisan key:generate

# Optimize Laravel
RUN php artisan config:cache \
 && php artisan route:cache \
 && php artisan view:cache


# ---------- Stage 2: Production ----------
FROM php:8.2-fpm-alpine

WORKDIR /var/www

# Install PHP extensions
RUN apk add --no-cache \
    libzip-dev \
    oniguruma-dev \
    icu-dev \
 && docker-php-ext-install pdo pdo_mysql mbstring zip intl

# Copy from builder
COPY --from=builder /var/www /var/www

# Set permissions
RUN chown -R www-data:www-data /var/www

EXPOSE 9002

CMD ["php-fpm"]
