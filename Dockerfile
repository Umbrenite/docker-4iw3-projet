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


# COMPOSER
FROM alpine AS composerApp

RUN apk update

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