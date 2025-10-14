FROM dunglas/frankenphp:php8.4 AS base
RUN install-php-extensions \
    pdo_pgsql \
    redis \
    zip \
    gd \
    mbstring \
    exif \
    bcmath \
    opcache \
    intl \
    pcntl
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN apt-get update && apt-get install -y \
    curl \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
ENV SERVER_NAME=:80

FROM base AS builder
WORKDIR /app
COPY . .
RUN composer install --no-dev --optimize-autoloader --no-interaction
RUN npm ci && npm run build:ssr

FROM base AS production
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
WORKDIR /app
COPY . .
COPY --from=builder /app/vendor /app/vendor
COPY --from=builder /app/node_modules /app/node_modules
COPY --from=builder /app/public/build /app/public/build
COPY --from=builder /app/bootstrap/ssr /app/bootstrap/ssr
RUN php artisan optimize && \
    chown -R www-data:www-data /app/storage /app/bootstrap/cache
