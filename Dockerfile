
# Mautic 6 설치를 위한 최적화된 Dockerfile
FROM php:8.1-apache

# 타임존 및 시스템 패키지
ENV TZ=Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    zip \
    unzip \
    git \
    libzip-dev \
    libicu-dev \
    libonig-dev \
    libxml2-dev \
    curl \
    wget \
    lsof \
    iputils-ping \
    nano \
    cron \
    default-mysql-client \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# NodeJS와 NPM
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get update && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# PHP 확장
RUN docker-php-ext-install pdo pdo_mysql mysqli opcache intl mbstring zip exif pcntl bcmath soap xml
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd

# Composer 설치
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Apache 설정
RUN a2enmod rewrite

# 작업 디렉토리
WORKDIR /var/www/html

# 볼륨 마운트용 디렉토리
RUN mkdir -p /var/www/mautic
RUN chown -R www-data:www-data /var/www/mautic

# php.ini 설정
RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini \
    && sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /usr/local/etc/php/php.ini \
    && sed -i 's/max_execution_time = 30/max_execution_time = 300/g' /usr/local/etc/php/php.ini \
    && sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 128M/g' /usr/local/etc/php/php.ini \
    && sed -i 's/post_max_size = 8M/post_max_size = 128M/g' /usr/local/etc/php/php.ini

# 엔트리포인트: 컨테이너 시작 시 Mautic 설치
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80
VOLUME ["/var/www/mautic"]
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]