# Container Base
FROM php:5.5-apache


ENV http_proxy ${HTTP_PROXY}
ENV https_proxy ${HTTP_PROXY}

COPY apache-run.sh /usr/bin/apache-run

RUN chmod a+x /usr/bin/apache-run

# Install libs
RUN apt-get update && apt-get install -y wget vim supervisor zip libfreetype6-dev libjpeg62-turbo-dev \
       libmcrypt-dev libpng12-dev libssl-dev libaio1 git libcurl4-openssl-dev libxslt-dev \
       libldap2-dev libicu-dev libc-client-dev libkrb5-dev libsqlite3-dev libedit-dev

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure hash --with-mhash \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install -j$(nproc) iconv bcmath mcrypt \
        gd mysql pdo_mysql calendar curl exif ftp gettext \
        hash xsl ldap intl imap pdo_sqlite mbstring \
        mcrypt pcntl readline shmop soap sockets wddx zip

# Install ssh2
RUN wget https://www.libssh2.org/download/libssh2-1.7.0.tar.gz && wget https://pecl.php.net/get/ssh2-0.13.tgz \
    && tar vxzf libssh2-1.7.0.tar.gz && tar vxzf ssh2-0.13.tgz \
    && cd libssh2-1.7.0 && ./configure \
    && make && make install \
    && cd ../ssh2-0.13 && phpize && ./configure --with-ssh2 \
    && make && make install \
    && echo "extension=ssh2.so" >> /usr/local/etc/php/conf.d/ssh2.ini

# Install oci8
RUN mkdir -p /opt/oci8 \
    && cd /opt/oci8 \
    && wget https://s3.amazonaws.com/simonetti-tests/oci8/instantclient-basic-linux.x64-12.1.0.2.0.zip \
    && wget https://s3.amazonaws.com/simonetti-tests/oci8/instantclient-sdk-linux.x64-12.1.0.2.0.zip \
    && unzip instantclient-sdk-linux.x64-12.1.0.2.0.zip \
    && unzip instantclient-basic-linux.x64-12.1.0.2.0.zip \
    && cd instantclient_12_1/ \
    && ln -s libclntsh.so.12.1 libclntsh.so \
    && ln -s libocci.so.12.1 libocci.so \
    && cd /tmp \
    && wget http://pecl.php.net/get/oci8-2.0.8.tgz \
    && tar xzf oci8-2.0.8.tgz \
    && cd oci8-2.0.8 \
    && phpize \
    && ./configure --with-oci8=shared,instantclient,/opt/oci8/instantclient_12_1/ \
    && make \
    && make install \
    && echo "extension=/tmp/oci8-2.0.8/modules/oci8.so" >> /usr/local/etc/php/conf.d/oci8.ini

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

# Run composer install
CMD usermod -u 1000 www-data \
    && cd /var/www/html && composer install && rm -rf var/cache/* var/logs/* \
    && chown -R www-data:www-data /var/www/html/var/cache && chmod 777 /var/www/html/var/cache \
    && chown -R www-data:www-data /var/www/html/var/logs && chmod 777 /var/www/html/var/logs \
    && apache2-foreground

EXPOSE 80