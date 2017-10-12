# CBQZ Systems and Tools

This project is a series of tools and an overall system for CBQZ functionality.
It includes everything that's part of the CBQZ ecosystem (apart from the data).

## Installation

This project expects to run inside a Linux host of some kind with a modern Perl
version.

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

## Service Startup

To read about how to start the application web service, run the following from
the project's root directory:

    perldoc app.pl
    ./app.pl --help

To start a development instance of the CBQZ web service:

    morbo -v -w app.pl -w config/app.yaml -w runtime/config.yaml -w lib -w templates app.pl

Note that at this point, while the service may be running, it by default binds
to `localhost:3000`. So you may need to tunnel that to gain access.
