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
dependencies.

    cpanm -n -f --with-develop --with-all-features --installdeps .
