#!/usr/bin/env perl
use exact;
use Config::App;

my ( $name, $host, $port, $username, $password ) = @{ Config::App->new->get('database') }{ qw(
    name host port username password
) };
system( qq{/bin/echo "DROP DATABASE $name" | /usr/bin/env mysql -h'$host' -P$port -u$username -p'$password'} );
