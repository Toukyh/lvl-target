# FROM php:8.0-fpm

# # Install dockerize so we can wait for containers to be ready
# ENV DOCKERIZE_VERSION 0.6.1

# RUN curl -s -f -L -o /tmp/dockerize.tar.gz https://github.com/jwilder/dockerize/releases/download/v$DOCKERIZE_VERSION/dockerize-linux-amd64-v$DOCKERIZE_VERSION.tar.gz \
#     && tar -C /usr/local/bin -xzvf /tmp/dockerize.tar.gz \
#     && rm /tmp/dockerize.tar.gz

# # Install Composer
# ENV COMPOSER_VERSION 2.1.5

# RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=$COMPOSER_VERSION

# # Install nodejs
# RUN curl -sL https://deb.nodesource.com/setup_14.x | bash

# RUN apt-get update \
#     && apt-get install -y --no-install-recommends \
#         libz-dev \
#         libpq-dev \
#         libjpeg-dev \
#         libpng-dev \
#         libssl-dev \
#         libzip-dev \
#         unzip \
#         zip \
#         nodejs \
#     && apt-get clean \
#     && pecl install redis \
#     && docker-php-ext-configure gd \
#     && docker-php-ext-configure zip \
#     && docker-php-ext-install \
#         gd \
#         exif \
#         opcache \
#         pdo_mysql \
#         pdo_pgsql \
#         pgsql \
#         pcntl \
#         zip \
#     && docker-php-ext-enable redis \
#     && rm -rf /var/lib/apt/lists/*;

# COPY ./docker/php/laravel.ini /usr/local/etc/php/conf.d/laravel.ini

# WORKDIR /usr/src/app

# RUN chown -R www-data:www-data .
FROM webdevops/php-nginx:8.3-alpine

# Installation dans votre Image du minimum pour que Docker fonctionne
RUN apk add oniguruma-dev libxml2-dev
RUN docker-php-ext-install \
        bcmath \
        ctype \
        fileinfo \
        mbstring \
        pdo_mysql \
        xml

# Installation dans votre image de Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Installation dans votre image de NodeJS
RUN apk add nodejs npm

ENV WEB_DOCUMENT_ROOT /app/public
ENV APP_ENV production
WORKDIR /app
COPY . .

# On copie le fichier .env.example pour le renommer en .env
# Vous pouvez modifier le .env.example pour indiquer la configuration de votre site pour la production
RUN cp -n .env.example .env

# Installation et configuration de votre site pour la production
# https://laravel.com/docs/10.x/deployment#optimizing-configuration-loading
RUN composer install --no-interaction --optimize-autoloader --no-dev
# Generate security key
RUN php artisan key:generate
# Optimizing Configuration loading
RUN php artisan config:cache
# Optimizing Route loading
RUN php artisan route:cache
# Optimizing View loading
RUN php artisan view:cache

# Compilation des assets de Breeze (ou de votre site)
RUN npm install
RUN npm run build

RUN chown -R application:application .
