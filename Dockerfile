FROM php:7.1-apache-buster

MAINTAINER Anthony Bretaudeau <anthony.bretaudeau@inrae.fr>

WORKDIR /var/www

RUN mkdir -p /usr/share/man/man1 /usr/share/man/man7

# Install packages and PHP-extensions
RUN apt-get -q update \
&& DEBIAN_FRONTEND=noninteractive apt-get -yq --no-install-recommends install \
    file libfreetype6 libjpeg62-turbo libpng16-16 libx11-6 libxpm4 gnupg \
    wget patch git unzip python-pip libyaml-dev libzip4 libzip-dev nano \
    python-dev python-setuptools cron libhwloc5 build-essential libssl-dev \
    zlib1g zlib1g-dev dirmngr libldap2-dev libonig-dev default-jre \
 && docker-php-ext-install mbstring zip ldap \
 && rm -rf /var/lib/apt/lists/* \
 && a2enmod rewrite && a2enmod proxy && a2enmod proxy_http && a2enmod authnz_ldap \
 && ln -s /usr/lib/x86_64-linux-gnu/libssl.so /usr/lib/x86_64-linux-gnu/libssl.so.10 \
 && ln -s /usr/lib/x86_64-linux-gnu/libcrypto.so /usr/lib/x86_64-linux-gnu/libcrypto.so.10 \
 && pip install bioblend

ENV TINI_VERSION v0.9.0
RUN set -x \
     && curl -fSL "https://github.com/krallin/tini/releases/download/$TINI_VERSION/tini" -o /usr/local/bin/tini \
     && chmod +x /usr/local/bin/tini

ENTRYPOINT ["/usr/local/bin/tini", "--"]

# Install composer
RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
    && curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
    && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" \
    && php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer --snapshot \
    && rm -f /tmp/composer-setup.*

# Install Symfony and bundles
RUN echo "memory_limit = -1" > $PHP_INI_DIR'/conf.d/memory-limit.ini' \
    && composer create-project symfony/framework-standard-edition --quiet bipaaccount "2.8.*" \
    && cd bipaaccount \
    && composer require symfony/assetic-bundle \
    && composer require jms/security-extra-bundle \
    && composer require jms/di-extra-bundle \
    && composer require zendframework/zend-ldap \
    && composer require twig/extensions \
    && sed -i '/\$bundles = array/a new Bipaa\\LdapBundle\\BipaaLdapBundle(),' app/AppKernel.php \
    && sed -i '/\$bundles = array/a new Bipaa\\AccountBundle\\BipaaAccountBundle(),' app/AppKernel.php \
    && sed -i '/\$bundles = array/a new Symfony\\Bundle\\AsseticBundle\\AsseticBundle(),' app/AppKernel.php \
    && sed -i '/\$bundles = array/a new JMS\\AopBundle\\JMSAopBundle(),' app/AppKernel.php \
    && sed -i '/\$bundles = array/a new JMS\\DiExtraBundle\\JMSDiExtraBundle(),' app/AppKernel.php \
    && sed -i '/\$bundles = array/a new JMS\\SecurityExtraBundle\\JMSSecurityExtraBundle(),' app/AppKernel.php \
    && sed -i '/src\/AppBundle/i "Bipaa\\\\LdapBundle\\\\": "vendor/bipaa/ldap-bundle/Bipaa/LdapBundle",' composer.json \
    && sed -i '/src\/AppBundle/i "Bipaa\\\\AccountBundle\\\\": "src/Bipaa/AccountBundle",' composer.json \
    && composer dump-autoload \
    && rm web/favicon.ico \
    && cd .. \
    && rm -rf html \
    && ln -s /var/www/bipaaccount/web html \
    && sed -i "/createFromGlobals/a Request::setTrustedProxies(array('127.0.0.1', \$request->server->get('REMOTE_ADDR')));" /var/www/bipaaccount/web/app.php

RUN mkdir -p /data/user /data/group

ENV MAILER_HOST='127.0.0.1'\
    MAILER_PORT="25"\
    MAILER_USER='null'\
    MAILER_PASS='null'\
    ENABLE_OP_CACHE=1\
    LDAP_HOST="localhost"\
    LDAP_USER_REACTIVATION_DELAY="365"\
    ACCOUNT_GALAXY_URL="http://localhost:8000"\
    ACCOUNT_GALAXY_APIKEY="fakekey"\
    ACCOUNT_HTTP_USER_DATA_ROOT="/data/user"\
    ACCOUNT_HTTP_GROUP_DATA_ROOT="/data/group"\
    BASE_URL_PATH='/'\
    DATA_URL_PATH="/data/"

ADD entrypoint.sh /
ADD scripts/ /scripts/
ADD apache/ /etc/apache2/sites-enabled/

ADD config/parameters.yml.tmpl /opt/parameters.yml.tmpl
ADD config/config.yml /var/www/bipaaccount/app/config/config.yml
ADD config/routing.yml /var/www/bipaaccount/app/config/routing.yml
ADD config/security.yml /var/www/bipaaccount/app/config/security.yml

CMD ["/entrypoint.sh"]
