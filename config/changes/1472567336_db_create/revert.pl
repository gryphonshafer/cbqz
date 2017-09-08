#!/usr/bin/env perl
use exact;
use Config::App;

my ( $dbname, $username, $password ) = @{ Config::App->new->get('database') }{ qw( dbname username password ) };
system( qq{/bin/echo "DROP DATABASE $dbname" | /usr/bin/env mysql -u$username -p'$password'} );
