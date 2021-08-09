FROM php:7.4.22-apache

ARG SENDY_VER=5.2.3
ARG SENDY_DIR=5.2.3

ENV SENDY_VERSION ${SENDY_VER}

RUN apt update && apt upgrade -y \
    # Install cron
    && apt install -y unzip cron \
    # Install php extensions
    && docker-php-ext-install calendar gettext mysqli \
    # Clean up
    && apt autoremove -y

# Copy files
COPY ./lib/${SENDY_DIR}/ /tmp

# Extract and install Sendy
RUN unzip /tmp/sendy-${SENDY_VER}.zip -d /tmp \
    && mkdir -p /tmp/sendy/uploads/csvs \
    && chmod -R 777 /tmp/sendy/uploads \
    && rm /tmp/sendy/includes/config.php \
    && mv /tmp/config.php /tmp/sendy/includes/config.php \
    && rm -rf /var/www/html \
    && mv /tmp/sendy /var/www/html \
    && mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini \
    && rm -rf /tmp/* \
    && echo "\nServerName \${SENDY_FQDN}" > /etc/apache2/conf-available/serverName.conf \
    && printf "\n\n# Ensure X-Powered-By is always removed regardless of php.ini or other settings.\n \
    Header always unset \"X-Powered-By\"\n \
    Header unset \"X-Powered-By\"\n" >> /var/www/html/.htaccess \
    && printf "[PHP]\nerror_reporting = E_ALL & ~E_NOTICE & ~E_STRICT & ~E_DEPRECATED\n" > /usr/local/etc/php/conf.d/error_reporting.ini

COPY sendy.ini /usr/local/etc/php/conf.d/sendy.ini

# Set permissions
RUN chown -R www-data:www-data /var/www/html

# Apache config
RUN a2enconf serverName

# Apache modules
RUN a2enmod rewrite headers

# Copy cron file to cron.d
COPY cron /etc/cron.d/cron

# Give execute permissions to cron
RUN chmod 0644 /etc/cron.d/cron \
    # Apply cron job
    && crontab /etc/cron.d/cron \
    # Create the log file
    && touch /var/log/cron.log

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
