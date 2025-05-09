
# Mautic 6 설치를 위한 최적화된 Dockerfile (서비스용)
FROM ghcr.io/nahdd123uosackr/mautic:base-8.1
# 실제 사용 시에는 아래와 같이 커스텀 베이스 이미지 태그로 교체하세요.
# 예시: FROM myorg/mautic-base:8.1

# 이하 기존 Dockerfile의 나머지 부분만 유지

# Composer 설치
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Apache 설정
RUN a2enmod rewrite \
    && sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/mautic/docroot|g' /etc/apache2/sites-available/000-default.conf

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


# .env 파일 포함
COPY .env /var/www/mautic/.env
# 엔트리포인트: 컨테이너 시작 시 Mautic 설치
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80
VOLUME ["/var/www/mautic"]
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]