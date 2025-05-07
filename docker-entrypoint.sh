#!/bin/bash
set -e

# Mautic 설치가 안 되어 있으면 설치

# config, logs, media, plugins 디렉토리만 남기고 나머지는 삭제 후 설치
if [ ! -f /var/www/mautic/composer.json ]; then
    echo "Checking /var/www/mautic for existing files..."
    for d in $(ls -A /var/www/mautic); do
        case "$d" in
            app)
                # app 하위의 config, logs, media, plugins만 남기고 삭제
                for subd in $(ls -A /var/www/mautic/app); do
                    case "$subd" in
                        config|logs|media|plugins)
                            ;;
                        *)
                            rm -rf "/var/www/mautic/app/$subd"
                            ;;
                    esac
                done
                ;;
            config|logs|media|plugins)
                # 유지
                ;;
            *)
                rm -rf "/var/www/mautic/$d"
                ;;
        esac
    done
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
