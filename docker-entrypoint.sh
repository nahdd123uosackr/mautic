#!/bin/bash
set -e

# DB가 없으면 생성
if [ -n "$MAUTIC_DB_HOST" ] && [ -n "$MAUTIC_DB_USER" ] && [ -n "$MAUTIC_DB_PASSWORD" ] && [ -n "$MAUTIC_DB_NAME" ]; then
  until mysql -h"$MAUTIC_DB_HOST" -u"$MAUTIC_DB_USER" -p"$MAUTIC_DB_PASSWORD" -e "USE $MAUTIC_DB_NAME;" 2>/dev/null; do
    echo "Waiting for MySQL to be ready..."
    sleep 2
  done
  mysql -h"$MAUTIC_DB_HOST" -u"$MAUTIC_DB_USER" -p"$MAUTIC_DB_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $MAUTIC_DB_NAME DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
fi

# /var/www/mautic/.env 파일이 없으면 .env.example 또는 .env.dist에서 복사
if [ ! -f /var/www/mautic/.env ]; then
    if [ -f /var/www/mautic/.env.example ]; then
        cp /var/www/mautic/.env.example /var/www/mautic/.env
    elif [ -f /var/www/.env ]; then
        cp /var/www/.env /var/www/mautic/.env
    fi
fi

# Mautic 설치가 안 되어 있으면 설치

# config, logs, media, plugins 디렉토리만 남기고 나머지는 삭제 후 설치
if [ ! -f /var/www/mautic/composer.json ]; then
    echo "Mautic not found. Installing..."
    TMPDIR=$(mktemp -d)
    composer create-project mautic/recommended-project:^6 "$TMPDIR" --no-interaction
    # 기존 config/logs/media/plugins 유지
    for d in config logs media plugins; do
        if [ -d /var/www/mautic/app/$d ]; then
            rm -rf "$TMPDIR/app/$d"
            cp -a "/var/www/mautic/app/$d" "$TMPDIR/app/"
        fi
    done
    cp -a "$TMPDIR/"* /var/www/mautic/
    chown -R www-data:www-data /var/www/mautic
    chmod -R 755 /var/www/mautic
    rm -rf "$TMPDIR"
    echo "Mautic installed successfully!"
fi

# PHP 메모리 한도 추가 설정
echo "memory_limit = 512M" > /usr/local/etc/php/conf.d/memory-limit.ini

# 크론 작업 등록
echo "* * * * * www-data /usr/local/bin/php /var/www/mautic/bin/console mautic:emails:send > /dev/null 2>&1" > /etc/cron.d/mautic
echo "*/5 * * * * www-data /usr/local/bin/php /var/www/mautic/bin/console mautic:campaigns:update > /dev/null 2>&1" >> /etc/cron.d/mautic
echo "*/10 * * * * www-data /usr/local/bin/php /var/www/mautic/bin/console mautic:campaigns:trigger > /dev/null 2>&1" >> /etc/cron.d/mautic
chmod 0644 /etc/cron.d/mautic

# 크론 서비스 시작
service cron start

# Apache 시작
exec apache2-foreground
