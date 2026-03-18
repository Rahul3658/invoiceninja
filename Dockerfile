# ---------- Stage 1: Build ----------
FROM php:8.2-fpm AS builder

WORKDIR /var/www

RUN apt-get update && apt-get install -y \
    git unzip curl libzip-dev zip \
    libpng-dev libjpeg-dev libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_mysql zip bcmath gd

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# 🔥 FIX: copy full project before composer
COPY . .

RUN composer install --no-dev --optimize-autoloader

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
    libpng-dev libjpeg-turbo-dev freetype-dev \
    && docker-php-ext-configure gd \
       --with-freetype \
       --with-jpeg \
    && docker-php-ext-install pdo pdo_mysql mbstring zip intl bcmath gd

# Copy from builder
COPY --from=builder /var/www /var/www

# Fix permissions
RUN chown -R www-data:www-data /var/www \
 && chmod -R 775 /var/www/storage /var/www/bootstrap/cache

# Correct port
EXPOSE 9000

CMD ["php-fpm"]
