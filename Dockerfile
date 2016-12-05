FROM php:7.0-apache

ARG php_ext
ARG wp_version=latest
ARG wp_locale=en_US

ENV WP_BUILD_VERSION wp_version
ENV WP_BUILD_LOCALE wp_locale

RUN \
	# install the PHP extensions we need
	apt-get update && apt-get install -y libpng12-dev libjpeg-dev && rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-install gd mysqli opcache $php_ext \
	# set recommended PHP.ini settings
	# see https://secure.php.net/manual/en/opcache.installation.php
	&& { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini \
	# Configure apache modules
	&& a2enmod rewrite expires \
	# Download wp cli
	&& curl -o /usr/local/bin/wp -SL https://github.com/wp-cli/wp-cli/releases/download/v0.24.1/wp-cli-0.24.1.phar \
	&& chmod +x /usr/local/bin/wp \
	&& wp --info --allow-root \
	# Download wordpress with wp cli to a temp dir
	&& wp core download --path=/usr/src/wordpress --locale=$wp_locale --version=$wp_version --allow-root \
	&& chown -R www-data:www-data /usr/src/wordpress

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
	&& ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compatibility

VOLUME /var/www/html
WORKDIR /var/www/html

# ENTRYPOINT resets CMD
ENTRYPOINT ["docker-entrypoint"]
CMD ["apache2-foreground"]
