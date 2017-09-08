#!/usr/bin/env perl
use exact;
use Config::App;
use Term::ReadKey 'ReadMode';

my ( $dbname, $username, $password ) = @{ Config::App->new->get('database') }{ qw( dbname username password ) };

print 'Database root password: ';
ReadMode('noecho');
my $root_password = <STDIN>;
ReadMode('original');
print "\n";
chomp($root_password);

system( qq{echo "$_" | /usr/bin/env mysql -uroot -p'$root_password'} ) for (
    qq{CREATE USER '$username'\@'localhost' IDENTIFIED BY '$password'},
    qq{GRANT ALL ON $dbname.* TO '$username'\@'localhost'},
);
