FROM php:7.4.10-fpm


# Clone the source code
RUN apt-get update && apt-get install -y git && \
    rm -rf /var/www && \
    cd /var && \
    git clone https://github.com/laravel/laravel.git www

# Install dependencies
RUN apt-get install -y \
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
    curl

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /var/www

# Install extensions
RUN docker-php-ext-install pdo_mysql mbstring zip exif pcntl
RUN docker-php-ext-configure gd \
    --with-jpeg=/usr/include/ \
    --with-freetype=/usr/include/

RUN docker-php-ext-install gd

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install nginx
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

# Grand permisson
RUN chmod -R 777 /var/www

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y nodejs \
    npm                       # note this one
	
RUN set -eux \
    && apt-get update \
    && apt-get install -y --no-install-recommends wget unzip fontconfig

#Installing Noto sans SC Fonts
RUN wget https://fonts.google.com/download?family=Noto%20Sans%20SC -O Noto_Sans_SC.zip \
    && unzip Noto_Sans_SC.zip -d /usr/share/fonts \
    && fc-cache 
    
#Clean up useless dependency packages
RUN set -eux \
    && apt-get autoremove \
    && apt-get autoclean \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN set -eux \
    && apt-get update \
    && apt-get install -y --no-install-recommends wget unzip \
        libfontenc1 libjpeg62-turbo libx11-6 libx11-data libxau6 libxcb1 \
        libxdmcp6 libxext6 libfontconfig1 libxrender1 x11-common xfonts-75dpi \
        xfonts-base xfonts-encodings xfonts-utils

RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.stretch_amd64.deb -O wkhtmltox_0.12.5-1.stretch_amd64.deb \
    && dpkg -i wkhtmltox_0.12.5-1.stretch_amd64.deb 
    
#Clean up useless dependency packages
RUN set -eux \
    && apt-get autoremove \
    && apt-get autoclean \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Expose port 9000 and start php-fpm server
EXPOSE 80
CMD ["sh", "-c", "php-fpm -D && nginx -g 'daemon off;'"]
