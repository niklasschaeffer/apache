FROM debian:latest

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get upgrade -y
RUN apt-get install wget curl build-essential ntp -y
RUN echo 'deb http://packages.dotdeb.org jessie all' > /etc/apt/sources.list.d/dotdeb.list
RUN curl http://www.dotdeb.org/dotdeb.gpg | apt-key add -
RUN cd /root && wget http://www.ijg.org/files/jpegsrc.v9b.tar.gz && tar xvfz jpegsrc.v9b.tar.gz && cd jpeg-9b && ./configure && make && make install
RUN apt-get update && apt-get install apt-utils curl git apache2 libapache2-mod-php7.0 php7.0-cli php7.0 php7.0-gd php7.0-mcrypt php7.0-curl php7.0-pgsql php7.0-imagick php7.0-intl php7.0-mysql php7.0-memcached php7.0-mbstring php7.0-opcache php7.0-xml php-pear php7.0-dev tofrodos nano vim wget -y

RUN git clone https://github.com/codeb2cc/phpMemcachedAdmin.git /var/www/memcachedadmin
RUN chown -R www-data:www-data /var/www/memcachedadmin

RUN ln -sf /dev/stdout /var/log/apache2/access.log
RUN ln -sf /dev/stderr /var/log/apache2/error.log

# Configure timezone and locale
RUN echo "Europe/Berlin" > /etc/timezone && apt-get install locales && \
	dpkg-reconfigure -f noninteractive tzdata && \
	dpkg-reconfigure -f noninteractive locales
RUN localedef -i de_DE -c -f UTF-8 -A /usr/share/locale/locale.alias de_DE.UTF-8 
	ENV LANG de_DE.UTF-8

# Let's set the default timezone in both cli and apache configs
RUN sed -i 's/\;date\.timezone\ \=/date\.timezone\ \=\ Europe\/Berlin/g' /etc/php/7.0/cli/php.ini
RUN sed -i 's/\;date\.timezone\ \=/date\.timezone\ \=\ Europe\/Berlin/g' /etc/php/7.0/apache2/php.ini

# Show Errors
RUN sed -i 's/display_errors = Off/display_errors = On/g' /etc/php/7.0/apache2/php.ini
RUN sed -i 's/display_errors = Off/display_errors = On/g' /etc/php/7.0/cli/php.ini

EXPOSE 80

RUN a2dissite 000-default
RUN a2dissite default-ssl

RUN mkdir /home/apps && chown -R www-data:www-data /home/apps

RUN ln -s /usr/bin/fromdos /usr/bin/dos2unix

RUN a2enmod rewrite

# Set Apache environment variables (can be changed on docker run with -e)
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_DOCUMENTROOT /var/www

RUN cd /root && curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/bin/composer 

RUN apt-get autoremove -y && apt-get clean -y

ENTRYPOINT ["/usr/sbin/apache2", "-D", "FOREGROUND"]

WORKDIR /home/apps