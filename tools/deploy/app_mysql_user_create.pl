#!/usr/bin/env perl
use exact;
use Config::App;
use CBQZ;
use Util::CommandLine 'podhelp';
use Term::ReadKey 'ReadMode';

my $cbqz = CBQZ->new;
my ( $host, $database, $username, $password ) =
    @{ $cbqz->config->get('database') }{ qw( host database username password ) };

my $origin = `/sbin/ip route|awk '/default/ { print \$3 }'`;
chomp($origin);
$origin = $host if ( $host eq 'localhost' or $host eq '127.0.0.1' or $host eq '0.0.0.0' );

print 'Database root password: ';
ReadMode('noecho');
my $root_password = <STDIN>;
ReadMode('original');
print "\n";
chomp($root_password);

$cbqz->config->put( qw( database settings mysql_multi_statements ) => 1 );
$cbqz->config->put( qw( database database ) => undef );
$cbqz->config->put( qw( database username ) => 'root' );
$cbqz->config->put( qw( database password ) => $root_password );

$cbqz->dq->sql(qq{
    CREATE USER '$username'\@'$origin' IDENTIFIED BY ?;
    GRANT ALL ON $database.* TO '$username'\@'$origin';
})->run($password);

=head1 NAME

app_mysql_user_create.pl - Create MySQL user account for initial CBQZ deployment

=head1 SYNOPSIS

    app_mysql_user_create.pl

=head1 DESCRIPTION

This program will create the MySQL user account needed by CBQZ. This is executed
only once during initial CBQZ deployment (as per deployment instructions).
