FROM alpine:3.20

WORKDIR /cbqz
COPY cpanfile .

RUN apk --no-cache add perl mariadb-connector-c && \
    apk --no-cache add --virtual .build-dependencies build-base curl wget perl-dev mariadb-dev && \
    curl -sL http://xrl.us/cpanm > cpanm && \
    chmod +x cpanm && \
    ./cpanm -n -f --installdeps . && \
    rm cpanm && \
    apk del .build-dependencies

VOLUME /cbqz
EXPOSE 3000

CMD [ "sh", "-c", "rm -f runtime/hypnotoad.pid && hypnotoad -f app.pl" ]
