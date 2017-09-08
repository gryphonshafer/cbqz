# CBQZ Systems and Tools

This project is a series of tools and an overall system for CBQZ functionality.
It includes everything that's part of the CBQZ ecosystem (apart from the data).

## Installation

This project expects to run inside a Linux host of some kind with a modern Perl
version. I recommend you don't use system Perl, but instead use something like
[Perlbrew](http://perlbrew.pl "Perlbrew"). This isn't required, though.

I even more recommend you use `cpanm` to install library dependencies. If you
don't have `cpanm` installed already, you can do so with this:

    # only run this if "cpanm" is not already available
    curl -L https://cpanmin.us | perl - --sudo App::cpanminus

With `cpanm` available, `cd` into the root directory of the project where the
`cpanfile` is located. Then run the following install all the project's library
dependencies:

    cpanm -n -f --with-develop --with-all-features --installdeps .

(Note that you'll likely need to have your database software server and client
and client developer libraries installed for the `cpanm` command to work
completely.)

### Application Settings

Look in `~/config/app.yaml` to find application settings. Consult the
[Config::App](https://metacpan.org/pod/Config::App) documentation for how to
setup custom override settings.

### Database Dependency

The application expects a database, which for the time being is MySQL. (This is
expected to change with time.) You need both the server and client along with
the client developer libraries.

Assuming MySQL is installed properly, you'll need to know the MySQL root
password to then run the following from the project's root directory:

    ./tools/deploy/app_mysql_user_create.pl

Once this is complete, run the following commands (still from the project's
root directory):

    dest init
    dest update

## Service Startup

To read about how to start the application web service, run the following from
the project's root directory:

    perldoc app.pl
    ./app.pl --help
