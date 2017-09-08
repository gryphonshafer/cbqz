#!/usr/bin/env perl
use exact;
use Config::App;

my ( $dbname, $username, $password ) = @{ Config::App->new->get('database') }{ qw( dbname username password ) };
system( qq{echo "CREATE DATABASE $dbname CHARACTER SET utf8 COLLATE utf8_general_ci" | /usr/bin/env mysql -u$username -p'$password'} );
