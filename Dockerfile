FROM debian:latest

RUN apt-get update && apt-get install -y \
    build-essential \
    perlbrew \
    nginx \
    mysql-server \
    libmariadbclient-dev-compat \
&& rm -rf /var/lib/apt/lists/*

SHELL [ "/bin/bash", "-c" ]

RUN perlbrew init && \
    echo "source ~/perl5/perlbrew/etc/bashrc" >> ~/.bashrc && \
    source ~/perl5/perlbrew/etc/bashrc && \
    perlbrew install --notest --noman --switch --as stable stable && \
    perlbrew install-cpanm && \
    perlbrew lib create stable@cbqz && \
    perlbrew switch stable@cbqz \
    perlbrew clean

COPY cpanfile /cbqz/cpanfile
WORKDIR /cbqz
RUN source ~/perl5/perlbrew/etc/bashrc && \
    cpanm -n -f --installdeps . && \
    rm -rf ~/.cpanm

COPY . /cbqz

VOLUME /cbqz/data
VOLUME /cbqz/runtime

EXPOSE 80
EXPOSE 3306

# CMD ./stack.bash

# docker build --compress --tag cbqz .

# docker run \
#     --detach \
#     --hostname cbqz.org \
#     --publish 7892:80 \
#     --name cbqz \
#     --restart unless-stopped \
#     --volume /opt/cbqz/config:/etc/cbqz \
#     --volume /opt/cbqz/logs:/var/log/cbqz \
#     --volume /opt/cbqz/data:/var/opt/cbqz \
#     cbqz

# docker exec --interactive --tty cbqz bash

# TODO:
#  - nginx config
#  - logs
#  - data
#  - `-v /some/content:/usr/share/nginx/html:ro`
