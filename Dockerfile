FROM php:5.6-fpm-alpine

       
RUN apk add --no-cache freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev && \
  docker-php-ext-configure gd \
    --with-gd \
    --with-freetype-dir=/usr/include/ \
    --with-png-dir=/usr/include/ \
    --with-jpeg-dir=/usr/include/ && \
  NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
  docker-php-ext-install -j${NPROC} gd && \
  apk del --no-cache freetype-dev libpng-dev libjpeg-turbo-dev

RUN docker-php-ext-install exif pdo_mysql
RUN docker-php-ext-install mysql mysqli
RUN apk add --no-cache libzip-dev && docker-php-ext-configure zip --with-libzip=/usr/include && docker-php-ext-install zip

RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
  && curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
  && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }"

RUN php /tmp/composer-setup.php
RUN mv composer.phar /usr/local/bin/composer
RUN rm /tmp/composer-setup.php

RUN apk add --no-cache  supervisor
RUN apk add --no-cache  git
RUN apk add --no-cache  sudo
RUN apk add --no-cache  nginx
RUN mkdir /run/nginx

RUN apk add openssh-client

RUN rm -rf /tmp/* /var/cache/apk/*


RUN mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.back
COPY config/nginx.conf /etc/nginx/nginx.conf


RUN mv /etc/supervisord.conf  /etc/supervisord.conf.back
COPY config/supervisord.conf /etc/supervisord.conf


RUN mv /usr/local/etc/php-fpm.d/www.conf  /usr/local/etc/php-fpm.d/www.conf.back
COPY config/fpm-pool.conf /usr/local/etc/php-fpm.d/www.conf


COPY config/php.ini /usr/local/etc/php/php.ini

#COPY --chown=nobody src/ /var/www/html/

WORKDIR "/usr/share/nginx"
ENTRYPOINT ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]

