#!/bin/bash
set -e

# Mautic 설치가 안 되어 있으면 설치
if [ ! -f /var/www/mautic/composer.json ]; then
    echo "Mautic not found. Installing..."
    composer create-project mautic/recommended-project:^6 /var/www/mautic --no-interaction
    chown -R www-data:www-data /var/www/mautic
    chmod -R 755 /var/www/mautic
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
