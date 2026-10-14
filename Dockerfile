FROM debian:12

RUN apt-get update && apt-get install -y \
    apache2 \
    php \
    php-cli \
    php-mysql \
    php-gd \
    php-curl \
    php-intl \
    php-mbstring \
    php-xml \
    php-zip \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

#voir si besoin d'une nouvelle version de dolibarr
RUN wget https://github.com/Dolibarr/dolibarr/archive/refs/tags/18.0.1.zip \
    && unzip 18.0.1.zip \
    && mv dolibarr-18.0.1/htdocs/* . \
    && rm -rf dolibarr-18.0.1 18.0.1.zip index.html \
    && mkdir -p /var/www/documents \
    && touch conf/conf.php \
    && chown -R www-data:www-data /var/www/html /var/www/documents

CMD ["apache2ctl", "-D", "FOREGROUND"]