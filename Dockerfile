# STAGE 1: Build
FROM composer as build

RUN mkdir /usr/src/app
WORKDIR /usr/src/app

# clone laravel source
RUN git clone https://github.com/laravel/laravel.git laravel-app && \
    cd laravel-app && composer install

# STAGE 2: Production Environment
FROM php:fpm

COPY --from=build /usr/src/app/laravel-app /var/www/

# Set working directory
WORKDIR /var/www

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libonig-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libzip-dev \
    locales \
    zip \
    jpegoptim optipng pngquant gifsicle \
    vim \
    unzip \
    git \
    curl

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install extensions
RUN docker-php-ext-install pdo_mysql mbstring zip exif pcntl
RUN docker-php-ext-configure gd \
    --with-jpeg=/usr/include/ \
    --with-freetype=/usr/include/

RUN docker-php-ext-install gd

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Add user for laravel application
RUN groupadd -g 1000 www
RUN useradd -u 1000 -ms /bin/bash -g www www

# Copy existing application directory contents
#COPY . /var/www

# Copy existing application directory permissions
RUN chown -R www:www /var/www

# Change current user to www
USER www

RUN apt-get update \
    && apt-get -y install wget \
    curl \
    gnupg \
    gnupg1 \
    gnupg2

#Download the Nginx repository signing key 
RUN wget http://nginx.org/keys/nginx_signing.key

#Add the Nginx signing key to a system
RUN apt-key add nginx_signing.key

#Append Nginx repository to /etc/apt/sources.list file
RUN echo "deb http://nginx.org/packages/debian/ stretch nginx" | tee -a /etc/apt/sources.list
RUN echo "deb-src http://nginx.org/packages/debian/ stretch nginx" | tee -a /etc/apt/sources.list

#Install Nginx package using the following command
RUN apt-get update; apt-get -y install nginx

# Copy config file to nginx folder
COPY ./nginx/conf.d/app.conf /etc/nginx/conf.d/default.conf

# Expose port 9000 and start php-fpm server
EXPOSE 80
CMD ["sh", "-c", "php-fpm -D && nginx -g 'daemon off;'"]
