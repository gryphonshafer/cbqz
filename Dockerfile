FROM alpine:latest
MAINTAINER Gryphon Shafer <g@cbqz.org>

WORKDIR /cbqz
COPY cpanfile .

RUN apk --no-cache add perl perl-dbd-mysql && \
    apk --no-cache add --virtual .build-dependencies build-base curl wget perl-dev mariadb-dev gcc-avr && \
    cp /usr/lib/gcc/avr/6.1.0/plugin/include/obstack.h /usr/include && \
    curl -sL http://xrl.us/cpanm > cpanm && chmod +x cpanm && \
    ./cpanm -n -f --installdeps . && rm -rf ~/.cpanm && \
    apk del .build-dependencies && rm ./cpanm && rm /usr/include/obstack.h

VOLUME /cbqz
EXPOSE 3000

CMD hypnotoad -f app.pl
