#!/usr/bin/env perl
use exact;
use Config::App;

my ( $dbname, $host, $port, $username, $password ) = @{ Config::App->new->get('database') }{ qw(
    dbname host port username password
) };
system( qq{/bin/echo "DROP DATABASE $dbname" | /usr/bin/env mysql -h'$host' -P$port -u$username -p'$password'} );
