FROM alpine:latest
MAINTAINER Gryphon Shafer <g@cbqz.org>

WORKDIR /cbqz
COPY cpanfile .

RUN apk --no-cache add perl mariadb-client-libs && \
    apk --no-cache add --virtual .build-dependencies build-base curl wget perl-dev mariadb-dev && \
    curl -sL http://xrl.us/cpanm > cpanm && chmod +x cpanm && \
    ./cpanm -n -f --installdeps . && rm -rf ~/.cpanm && \
    apk del .build-dependencies && rm ./cpanm

COPY . .

COPY config/app.yaml /cbqz/app.yaml
ENV  CONFIGAPPINIT   /cbqz/app.yaml

VOLUME /cbqz/runtime
EXPOSE 3000

CMD hypnotoad -f app.pl
