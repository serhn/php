FROM php:7.4-fpm-alpine

       
RUN apk add --no-cache freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev && \
  docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg && \
  NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
  docker-php-ext-install -j${NPROC} gd && \
  apk del --no-cache freetype-dev libpng-dev libjpeg-turbo-dev
  
  
RUN set -ex \
    && apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS imagemagick-dev libtool \
    && export CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS" \
    && pecl install imagick-3.4.3 \
    && docker-php-ext-enable imagick \
    && apk add --no-cache --virtual .imagick-runtime-deps imagemagick \
    && apk del .phpize-deps \
    && rm -rf /tmp/* /var/cache/apk/*  

RUN docker-php-ext-install exif pdo_mysql
RUN docker-php-ext-install mysqli

#RUN apt-get install libsodium-dev -y
#RUN docker-php-ext-install sodium

RUN apk add --no-cache libzip-dev && docker-php-ext-configure zip && docker-php-ext-install zip

RUN apk add --no-cache libintl icu icu-dev && docker-php-ext-configure intl && docker-php-ext-install intl

RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
  && curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
  && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }"

RUN php /tmp/composer-setup.php
RUN mv composer.phar /usr/local/bin/composer
RUN rm /tmp/composer-setup.php

RUN apk add --no-cache  supervisor
RUN apk add --no-cache  git

RUN rm -rf /tmp/* /var/cache/apk/*

RUN echo '* * * * * cd /usr/share/nginx && php artisan schedule:run >> /dev/null 2>&1' > /etc/crontabs/www-data

RUN mv /etc/supervisord.conf  /etc/supervisord.conf.back
RUN echo -e "[supervisord]\nnodaemon=true\n" > /etc/supervisord.conf
RUN echo -e "[program:php-fpm]\ncommand=php-fpm -F\nstdout_logfile=/dev/stdout\nstdout_logfile_maxbytes=0\nstderr_logfile=/dev/stderr\nstderr_logfile_maxbytes=0\nautorestart=true\nstartretries=0\n" >> /etc/supervisord.conf
RUN echo -e "[program:phpjob]\ncommand=php artisan queue:work --tries=3\nuser=www-data\nnumprocs=1\ndirectory=/usr/share/nginx\nautostart=true\nautorestart=true\nstdout_logfile=/dev/stdout\nstderr_logfile=/dev/stderr\n" >> /etc/supervisord.conf
RUN echo -e "[program:crond]\ncommand=crond\nstdout_logfile=/dev/stdout\nstdout_logfile_maxbytes=0\nstderr_logfile=/dev/stderr\nstderr_logfile_maxbytes=0\nautorestart=true\nstartretries=0\n" >> /etc/supervisord.conf


ENTRYPOINT ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]

