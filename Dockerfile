
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
RUN php81 -r "if (hash_file('sha384', 'composer-setup.php') === 'edb40769019ccf227279e3bdd1f5b2e9950eb000c3233ee85148944e555d97be3ea4f40c3c2fe73b22f875385f6a5155') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php81 composer-setup.php
RUN php81 -r "unlink('composer-setup.php');"

# Si on est ici, tout s'est bien passé :p
RUN php81 composer.phar

# SYMFONY APP
FROM alpine AS symfonyApp

WORKDIR /src/app
RUN apk update && apk add --no-cache \
		acl \
		fcgi \
		file \
		gettext \
		git \
        linux-headers \
		npm \
	;

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

RUN apk update