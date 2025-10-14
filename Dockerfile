FROM dunglas/frankenphp:php8.4 AS base

RUN install-php-extensions \
    pdo_pgsql \
    redis \
    zip \
    gd \
    opcache \
    intl \
    pcntl

ENV SERVER_NAME=:80

FROM node:22-alpine AS node

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM base AS production

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

COPY . /app

COPY --from=node /app/public/build /app/public/build
COPY --from=node /app/bootstrap/ssr /app/bootstrap/ssr

RUN composer install --no-dev --optimize-autoloader --no-interaction && \
    php artisan optimize && \
    chown -R www-data:www-data /app/storage /app/bootstrap/cache

CMD ["php", "artisan", "octane:frankenphp"]
