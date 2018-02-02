#!/usr/bin/env perl
use exact;
use Config::App;

my $config = Config::App->new;
my ( $name, $host, $port, $username, $password ) = @{ Config::App->new->get('database') }{ qw(
    name host port username password
) };

my $command = q{
    /usr/bin/env mysqldump --skip-opt --skip-disable-keys --skip-comments --skip-set-charset --no-data
    } . "-h'$host' -P$port -u$username -p'$password' $name" . q{
    | /bin/sed -e '/^\/\*![0-9]* SET/d'
    | /bin/sed -e 's/`//g'
    | /bin/sed -e 's/^\/\*![0-9]* CREATE.*TRIGGER/CREATE TRIGGER/'
    | /bin/sed -e 's/ \*\/;;/;/'
    | /bin/sed -e '/^DELIMITER/d'
    | /bin/sed -e '/^$/d'
    | /bin/sed -e 's/;/;\n/'
    | /bin/sed -e 's/^  /    /'
} . '> ' . $config->get( qw( config_app root_dir ) ) . '/db/schema.sql';

$command =~ s/\s*\n\s*/ /g;
system($command);
