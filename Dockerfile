FROM php:8.1-apache

# 타임존 설정
ENV TZ=Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 필요한 시스템 패키지 설치
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

# NodeJS와 NPM 설치
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get update && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# PHP 확장 설치
RUN docker-php-ext-install pdo pdo_mysql mysqli opcache intl mbstring zip exif pcntl bcmath soap xml
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd

# PHP 설정 최적화
COPY php.ini-production /usr/local/etc/php/php.ini
RUN sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /usr/local/etc/php/php.ini \
    && sed -i 's/max_execution_time = 30/max_execution_time = 300/g' /usr/local/etc/php/php.ini \
    && sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 128M/g' /usr/local/etc/php/php.ini \
    && sed -i 's/post_max_size = 8M/post_max_size = 128M/g' /usr/local/etc/php/php.ini

# Composer 설치
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Apache 설정
RUN a2enmod rewrite

# 작업 디렉토리 설정
WORKDIR /var/www/html

# 기본 디렉토리 구조 생성 (볼륨 마운트를 위한 준비)
RUN mkdir -p /var/www/mautic

# Apache 설정 변경
RUN echo '<VirtualHost *:80>\n\
    DocumentRoot /var/www/mautic/docroot\n\
    <Directory /var/www/mautic/docroot>\n\
        AllowOverride All\n\
        Require all granted\n\
    </Directory>\n\
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# 권한 설정
RUN chown -R www-data:www-data /var/www/mautic

# entrypoint 스크립트 생성
RUN echo '#!/bin/bash\n\
if [ ! -f /var/www/mautic/composer.json ]; then\n\
    echo "Mautic not found. Installing..."\n\
    cd /var/www\n\
    composer create-project mautic/recommended-project:^6 /var/www/mautic --no-interaction\n\
    chown -R www-data:www-data /var/www/mautic\n\
fi\n\
apache2-foreground\n\
' > /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# PHP 확장 설정 조정
RUN echo "date.timezone = UTC" >> /usr/local/etc/php/conf.d/timezone.ini

VOLUME ["/var/www/mautic"]

EXPOSE 881

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]