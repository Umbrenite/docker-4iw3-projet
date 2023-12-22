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
FROM alpine AS postgresDB

RUN apk update

# ADMINER
FROM alpine AS adminer

RUN apk update




