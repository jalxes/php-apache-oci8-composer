#!/usr/bin/env bash

if [[ $XDEBUG_ENABLED == true ]]; then
	docker-php-ext-enable xdebug
	echo "xdebug.var_display_max_depth=5" >> /usr/local/etc/php/conf.d/xdebug.ini
fi

usermod -u 1000 www-data \
    && cd /var/www/html && composer install && rm -rf var/cache/* var/logs/* \
    && chown -R www-data:www-data /var/www/html/var/cache && chmod 777 /var/www/html/var/cache \
    && chown -R www-data:www-data /var/www/html/var/logs && chmod 777 /var/www/html/var/logs \
    && chown -R www-data:www-data /var/www/html/var/sessions && chmod 777 /var/www/html/var/sessions \
    && apache2-foreground
