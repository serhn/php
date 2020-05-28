FROM php:7.2-fpm
RUN apt-get update -y && apt-get install -y libpng-dev libsqlite3-dev libjpeg62-turbo-dev libfreetype6-dev 
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ 
RUN docker-php-ext-install gd pdo pdo_sqlite exif pdo_mysql zip mysqli

#PGSQL BEGIN
RUN apt-get install -y libpq-dev
RUN docker-php-ext-install pdo_pgsql
#PGSQL END

RUN apt-get install -y mysql-client
RUN apt-get install -y net-tools vim
RUN apt-get install -y git

# build-essential
RUN apt-get install -y procps
RUN apt-get install -y nmap mc tmux screen
RUN apt-get install -y dnsutils 
RUN apt-get install -y gnupg2

#RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install -y nodejs


RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
  && curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
  && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }"

RUN php /tmp/composer-setup.php
RUN mv composer.phar /usr/local/bin/composer
RUN rm /tmp/composer-setup.php

RUN apt-get install -y libmagickwand-dev
RUN pecl install imagick-beta
RUN echo "extension=imagick.so" > /usr/local/etc/php/conf.d/ext-imagick.ini


RUN pecl install xdebug
RUN docker-php-ext-enable xdebug
RUN echo  "\
xdebug.remote_port=9000 \n\
xdebug.remote_enable=on \n\ 
xdebug.remote_log=/var/log/xdebug.log " >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN touch /var/log/xdebug.log

RUN apt-get install -y ssmtp
RUN echo "[mail function]\nsendmail_path = /usr/sbin/ssmtp -t" > /usr/local/etc/php/conf.d/sendmail.ini
RUN echo "mailhub=mailcatcher:1025\nUseTLS=NO\nFromLineOverride=YES" > /etc/ssmtp/ssmtp.conf


RUN echo  "\
syntax on \n\
autocmd FileType php set omnifunc=phpcomplete#CompletePHP \n\
set number \n\
:set encoding=utf-8 \n\
:set fileencoding=utf-8"  >> /root/.vimrc

RUN apt-get -y install cron
RUN touch /etc/cron.d/crontab
RUN chmod 0644 /etc/cron.d/crontab
RUN service cron start
