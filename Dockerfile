# Verwende ein aktuelles PHP-Image mit Apache
FROM php:7.4-apache

# Aktualisierte PHP-Erweiterungen installieren
RUN set -ex; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libjpeg-dev \
		libpng-dev \
		libpq-dev \
    zlib1g-dev \
    libzip-dev \
    libfreetype6-dev \
	; \
	docker-php-ext-configure gd --with-jpeg=/usr/include/ --with-freetype=/usr/include/; \
	docker-php-ext-install -j "$(nproc)" \
		gd \
		opcache \
		pdo_mysql \
		pdo_pgsql \
		zip \
	; \
    # Installiere MySQL-Client
   apt-get install -y default-mysql-client; \
    # Clean up
	rm -rf /var/lib/apt/lists/*

# Enable Apache modules
RUN a2enmod rewrite

# Empfohlene PHP.ini-Einstellungen
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
		echo 'post_max_size = 200M'; \
		echo 'upload_max_filesize = 200M'; \
		echo 'memory_limit = 512M'; \
		echo 'max_execution_time = 600'; \
	} > /usr/local/etc/php/conf.d/drupal-recommended.ini

# Drush installieren
RUN php -r "readfile('https://github.com/drush-ops/drush/releases/download/8.1.10/drush.phar');" > /usr/local/bin/drush && \
    chmod +x /usr/local/bin/drush

# Restart Apache to apply the changes
RUN service apache2 restart

# Arbeitsverzeichnis festlegen
WORKDIR /var/www/html

# Drupal herunterladen und installieren
ENV DRUPAL_VERSION 7.66
ENV DRUPAL_MD5 fe1b9e18d7fc03fac6ff4e039ace5b0b

RUN curl -fSL "https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz" -o drupal.tar.gz \
	&& echo "${DRUPAL_MD5} *drupal.tar.gz" | md5sum -c - \
	&& tar -xz --strip-components=1 -f drupal.tar.gz \
	&& rm drupal.tar.gz \
	&& chown -R www-data:www-data sites modules themes
