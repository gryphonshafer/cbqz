#!/usr/bin/env perl
use exact;
use Config::App;
use CBQZ;
use Util::CommandLine 'podhelp';
use Term::ReadKey 'ReadMode';

print 'Database root password: ';
ReadMode('noecho');
my $root_password = <STDIN>;
ReadMode('original');
print "\n";
chomp($root_password);

my $cbqz = CBQZ->new;
my ( $database, $username ) = @{ $cbqz->config->get('database') }{ qw( database username ) };

$cbqz->config->put( qw( database username ) => 'root' );
$cbqz->config->put( qw( database password ) => $root_password );

my $dq      = $cbqz->dq;
my ($host)  = @{ $dq->sql('SELECT Host FROM mysql.user WHERE User = ?')->run($username)->next->row };
my $definer = "`$username`\@`$host`";

for my $trigger ( @{ $dq->sql(q{
    SELECT trigger_name, definer FROM information_schema.triggers WHERE trigger_schema = ?
})->run($database)->all({}) } ) {
    my $trigger_sql = $dq->sql( 'SHOW CREATE TRIGGER ' . $trigger->{trigger_name} )->run->next->row->[2];
    $trigger_sql =~ s/\bDEFINER=`[^`]+`@`[^`]+`/DEFINER=$definer/;

    $dq->sql( 'DROP TRIGGER ' . $trigger->{trigger_name} )->run;
    $dq->sql($trigger_sql)->run;
}

=head1 NAME

alter_triggers_definer.pl - Alter MySQL triggers' "DEFINER" values

=head1 SYNOPSIS

    alter_triggers_definer.pl

=head1 DESCRIPTION

This program will alter MySQL triggers' "DEFINER" values.
