# CBQZ Systems and Tools

This project is a series of tools and an overall system for CBQZ functionality.
It includes everything that's part of the CBQZ ecosystem (apart from the data).

## Local/Developer Installation

This project expects to run inside a Linux host of some kind with a modern Perl
version. The following are instructions for installation in a local or developer
enviornment (i.e. native or inside virtual machine instead of inside Docker).

These instructions would also work for a production enviornment, but for such,
you may want to consider the Docker option explained below.

### Perl

I recommend you don't use system Perl, but instead use something like
[Perlbrew](http://perlbrew.pl "Perlbrew"). This isn't required, though.

I even more recommend you use `cpanm` to install library dependencies. To
install, you can install through Perlbrew, which is best if you have Perlbrew,
or directly:

    # via Perlbrew
    perlbrew install-cpanm

    # directly
    curl -L https://cpanmin.us | perl - --sudo App::cpanminus

### Database

The application expects a database, which for the time being is MySQL. (This is
expected to change with time.) You need both the server and client along with
the client developer libraries.

To install on `apt` systems, run the following:

    sudo apt-get install mysql-common mysql-client mysql-server default-libmysqlclient-dev

You'll need to know the MySQL root password, and it'll be helpful to be able to
login as that root user while not being the system root. To change the MySQL
root password and allow for access while not being system root, you can try this
(but you'll need to be the system root user):

    service mysql stop
    echo "
        UPDATE mysql.user SET
            Password = PASSWORD('new_root_password'),
            password_expired = 'N', plugin = ''
        WHERE User = 'root' AND Host = 'localhost';
        FLUSH PRIVILEGES;
    " > password.sql
    mysqld_safe --init-file=password.sql
    shred -u password.sql
    service mysql start

### Perl Libraries

Next, you'll need to install a bunch of Perl library dependencies. You should be
able to do this fairly easily, though; it'll just take a long time to run.
Change your working directory to the CBQZ project root directory, then run
`cpanm` as follows:

    # assuming "cbqz" is the CBQZ root directory and is in your home directory
    cd ~/cbqz
    cpanm -n -f --with-develop --with-all-features --installdeps .

### Application Settings

Look in `~/config/app.yaml` to find application settings. Consult the
[Config::App](https://metacpan.org/pod/Config::App) documentation for how to
setup custom override settings.

### Application Enviornment

Assuming everything up until here is done and working properly, you'll need to
have the MySQL root password handy, then run the following from the project's
root directory:

    ./tools/deploy/app_mysql_user_create.pl

Once this is complete, run the following commands (still from the project's
root directory):

    dest init
    dest update

And finally, you'll need to create two directories:

    mkdir runtime data

### Service Startup

To read about how to start the application web service, run the following from
the project's root directory:

    perldoc app.pl
    ./app.pl --help

To start a development instance of the CBQZ web service:

    morbo -v -w app.pl -w config/app.yaml -w runtime/config.yaml -w lib -w templates app.pl

Note that at this point, while the service may be running, it by default binds
to `localhost:3000`. So you may need to tunnel that to gain access.

### Materials Loading

Although the application system will be technically operational in the previous
step, you can't really do anything useful like work in the questions editor or
operate the quiz room page without adding reference materials.

To do that, use the `material_load.pl` program located in the `tools/data`
directory.

    ./tools/data/material_load.pl -n '2017 Corinthians' -k etc/2017_kvl.csv -m etc/2017_materials.csv

### Upgrading and Staying Current

After pulling CBQZ code updates, you may need to update other aspects of your
enviornment. Generally speaking, you can do that with from the project's root
directory with:

    cpanm -n -f --with-develop --with-all-features --installdeps .
    dest update

Also check changes on this file for clues as to any other dependencies needed.

## Docker Installation

The following are instructions for installation and execution of CBQZ via use of
Docker images and containers.

### Build the CBQZ Docker Image

The following as an exampe of how to build a CBQZ Docker image.

    docker build --compress --tag cbqz .

### Run a New CBQZ Docker Container

The following as an exampe of how to create and start new a CBQZ Docker
container based on the CBQZ Docker image.

    docker run \
        --detach \
        --hostname cbqz_docker \
        --publish 3000:3000 \
        --name cbqz \
        --restart unless-stopped \
        --volume /opt/cbqz:/cbqz/runtime \
        cbqz

The instance of CBQZ will contain a default configuration (which is a copy of
the `~/config/app.yaml` file committed in revision control). To override any of
these defaults, create a `/opt/cbqz/app.yaml` configuration file.

See above for a configuration file explaination.

### Docker Container Shell

The following as an exampe of how to get shell access of a running CBQZ
container.

    docker exec --interactive --tty cbqz sh

Note that this gives you `sh` access, not `bash` or anything more advanced
since these other shells are not installed in the image/container for space
considerations.

### Nginx Container

Although it's possible to run CBQZ through the Hypnotoad-based "cbqz" container
above, it'll probably be a better option to run Nginx to proxy pass to the
CBQZ service.

    docker run \
        --detach \
        --publish 80:80 \
        --name cbqz-nginx \
        --restart unless-stopped \
        --volume `pwd`/etc/nginx.conf:/etc/nginx/nginx.conf:ro \
        --volume `pwd`:/cbqz:ro \
        --volume /opt/nginx/log:/var/log/nginx \
        nginx:alpine
