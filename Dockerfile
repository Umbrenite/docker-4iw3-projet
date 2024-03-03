ARG PHP_VERSION=8.1
ARG CADDY_VERSION=2

# COMPOSER
FROM alpine AS composerApp

# Install des packages nécessaires
RUN apk update && apk add --no-cache \
		php81 \
		php81-curl \
		php81-openssl \
		php81-json \
		php81-phar \
		php81-mbstring \
		php81-iconv \
	;

# Installation de composer dans alpine
RUN php81 -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php81 -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php81 composer-setup.php
RUN php81 -r "unlink('composer-setup.php');"

# Si on est ici, tout s'est bien passé :p
RUN php81 composer.phar

# DATABASE
FROM postgres:alpine AS postgresDB

RUN apk add --no-cache postgresql-client

ENV POSTGRES_USER=${POSTGRES_USER} \
    POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
    POSTGRES_DB=${POSTGRES_DB}

COPY create_table.sql /docker-entrypoint-initdb.d/
COPY insert_todo.sql /docker-entrypoint-initdb.d/

# ADMINER
FROM alpine AS adminer

RUN apk -U upgrade \
 && apk add -t build-dependencies \
    ca-certificates \
    openssl \
 && apk add \
    su-exec \
    tini \
    php81 \
    php81-session \
    php81-pdo_mysql \
    php81-pdo_pgsql \
    php81-pdo_sqlite \
    curl;

RUN mkdir -p /usr/share/adminer/ && \
    curl -Lo /usr/share/adminer/adminer.php https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1-en.php

EXPOSE 8080

CMD ["php81", "-S", "0.0.0.0:8080", "-t", "/usr/share/adminer/"]

# SYMFONY
FROM php:${PHP_VERSION}-fpm-alpine AS app_php

ARG STABILITY="stable"
ENV STABILITY ${STABILITY}

ARG SYMFONY_VERSION=""
ENV SYMFONY_VERSION ${SYMFONY_VERSION}

ENV APP_ENV=prod

WORKDIR /srv/app

RUN apk add --no-cache \
		acl \
		fcgi \
		file \
		gettext \
		git \
        linux-headers \
		npm \
	;

RUN set -eux; \
    apk add --no-cache --virtual .build-deps $PHPIZE_DEPS; \
    apk add --no-cache libpng libpng-dev; \
    docker-php-ext-install gd; \
    apk del .build-deps;


RUN set -eux; \
	apk add --no-cache --virtual .build-deps \
		$PHPIZE_DEPS \
		icu-data-full \
		icu-dev \
		libzip-dev \
		zlib-dev \
	; \
	\
	docker-php-ext-configure zip; \
	docker-php-ext-install -j$(nproc) \
		intl \
		zip \
	; \
	pecl install \
		apcu \
	; \
	pecl clear-cache; \
	docker-php-ext-enable \
		apcu \
		opcache \
	; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --no-cache --virtual .app-phpexts-rundeps $runDeps; \
	\
	apk del .build-deps

RUN apk add --no-cache --virtual .pgsql-deps postgresql-dev; \
	docker-php-ext-install -j$(nproc) pdo pdo_pgsql iconv; \
	apk add --no-cache --virtual .pgsql-rundeps so:libpq.so.5; \
	apk del .pgsql-deps

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY docker/php/conf.d/app.ini $PHP_INI_DIR/conf.d/
COPY docker/php/conf.d/app.prod.ini $PHP_INI_DIR/conf.d/

COPY docker/php/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf
RUN mkdir -p /var/run/php

COPY docker/php/docker-healthcheck.sh /usr/local/bin/docker-healthcheck
RUN chmod +x /usr/local/bin/docker-healthcheck

HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD ["docker-healthcheck"]

COPY docker/php/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

ENTRYPOINT ["docker-entrypoint"]
CMD ["php-fpm"]

ENV COMPOSER_ALLOW_SUPERUSER=1
ENV PATH="${PATH}:/root/.composer/vendor/bin"

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# prevent the reinstallation of vendors at every changes in the source code
COPY composer.* symfony.* ./
RUN set -eux; \
    if [ -f composer.json ]; then \
		composer install --ignore-platform-req=ext-gd --prefer-dist --no-dev --no-autoloader --no-scripts --no-progress; \
		composer clear-cache; \
    fi

# copy sources
COPY . .
RUN rm -Rf docker/

ARG DATABASE_URL=""
ENV DATABASE_URL=${DATABASE_URL}

RUN set -eux; \
	mkdir -p var/cache var/log;

# Dev image
FROM app_php AS app_php_dev

ENV APP_ENV=dev XDEBUG_MODE=off
VOLUME /srv/app/var/

RUN rm $PHP_INI_DIR/conf.d/app.prod.ini; \
	mv "$PHP_INI_DIR/php.ini" "$PHP_INI_DIR/php.ini-production"; \
	mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

COPY docker/php/conf.d/app.dev.ini $PHP_INI_DIR/conf.d/

RUN set -eux; \
	apk add --no-cache --virtual .build-deps $PHPIZE_DEPS; \
	pecl install xdebug; \
	docker-php-ext-enable xdebug; \
	apk del .build-deps

RUN rm -f .env.local.php

# "encore" command
COPY package*.json .
RUN npm install

FROM caddy:${CADDY_VERSION}-builder-alpine AS app_caddy_builder

RUN xcaddy build \
	--with github.com/dunglas/mercure \
	--with github.com/dunglas/mercure/caddy \
	--with github.com/dunglas/vulcain \
	--with github.com/dunglas/vulcain/caddy

FROM caddy:${CADDY_VERSION} AS app_caddy

WORKDIR /srv/app

COPY --from=app_caddy_builder /usr/bin/caddy /usr/bin/caddy
COPY --from=app_php /srv/app/public public/
COPY docker/caddy/Caddyfile /etc/caddy/Caddyfile
