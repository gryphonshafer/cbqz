#!/usr/bin/env perl
use exact;
use Config::App;
use Util::CommandLine qw( options pod2usage );
use Text::CSV_XS 'csv';
use CBQZ;

my $settings = options( qw( set|s=s questions|q=s ) );
pod2usage unless ( $settings->{set} and $settings->{questions} );

my $dq = CBQZ->new->dq;
my $set_id = $dq->sql('SELECT question_set_id FROM question_set WHERE name = ?')
    ->run( $settings->{set} )->value;
die "Set name $settings->{set} not found\n" unless ($set_id);

my $insert = $dq->sql(q{
    INSERT INTO question ( question_set_id, type, book, chapter, verse, question, answer )
    VALUES ( ?, ?, ?, ?, ?, ?, ? )
});

$insert->run( $set_id, @$_ ) for ( @{ csv( in => $settings->{questions} ) } );

=head1 NAME

questions_load.pl - Load questions data into the database as a new questions set

=head1 SYNOPSIS

    questions_load.pl OPTIONS
        -s|set       QUESTIONS_SET_NAME
        -q|questions QUESTIONS_DATA_FILE
        -h|help
        -m|man

=head1 DESCRIPTION

This program will load questions data into the database as a new questions set.
