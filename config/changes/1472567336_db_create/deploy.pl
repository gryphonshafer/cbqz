#!/usr/bin/env perl
use exact;
use Config::App;

my ( $name, $host, $port, $username, $password ) = @{ Config::App->new->get('database') }{ qw(
    name host port username password
) };
system(
    qq{echo "CREATE DATABASE $name CHARACTER SET utf8 COLLATE utf8_general_ci" | } .
    qq{/usr/bin/env mysql -h'$host' -P$port -u$username -p'$password'}
);
