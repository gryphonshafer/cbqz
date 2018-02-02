#!/usr/bin/env perl
use exact;
use Config::App;
use Util::CommandLine 'podhelp';
use Term::ReadKey 'ReadMode';

my ( $name, $host, $port, $username, $password ) = @{ Config::App->new->get('database') }{ qw(
    name host port username password
) };

my $origin = `/sbin/ip route|awk '/default/ { print \$3 }'`;
chomp($origin);
$origin = $host if ( $host eq 'localhost' or $host eq '127.0.0.1' or $host eq '0.0.0.0' );

print 'Database root password: ';
ReadMode('noecho');
my $root_password = <STDIN>;
ReadMode('original');
print "\n";
chomp($root_password);

system( qq{echo "$_" | /usr/bin/env mysql -h'$host' -P$port -uroot -p'$root_password'} ) for (
    qq{CREATE USER '$username'\@'$origin' IDENTIFIED BY '$password'},
    qq{GRANT ALL ON $name.* TO '$username'\@'$origin'},
);

=head1 NAME

app_mysql_user_create.pl - Create MySQL user account for initial CBQZ deployment

=head1 SYNOPSIS

    app_mysql_user_create.pl

=head1 DESCRIPTION

This program will create the MySQL user account needed by CBQZ. This is executed
only once during initial CBQZ deployment (as per deployment instructions).
