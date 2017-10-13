#!/usr/bin/env perl
use exact;
use Text::CSV_XS 'csv';
use Util::CommandLine qw( options pod2usage );

my $settings = options( qw( input|i=s output|o=s ) );
pod2usage unless ( $settings->{input} and $settings->{output} );

my $data;
open( my $in, '<', $settings->{input} ) or die $!;
while (<$in>) {
    s/\r//g;
    s/[\x91\x92]/'/g;
    s/[\x93\x94]/"/g;
    s/\x97/\./g;
    s/\xBB/>/g;
    chomp;

    my $line;
    @$line{ qw( type book chapter verse question answer ) } = split(/\t/);

    next unless ( $line->{answer} );

    $line->{type} = 'MACR' if ( $line->{type} eq 'CRMA' );
    $line->{type} = 'MACVR' if ( $line->{type} eq 'CVRMA' );
    $line->{type} = 'Q' if ( $line->{type} eq 'QT' );

    $line->{verse} =~ s/\D.*$//g;

    $line->{question} =~ s/^"|"$//g;
    $line->{answer}   =~ s/^"|"$//g;
    $line->{question} =~ s/^\s+|\s+$//g;
    $line->{answer}   =~ s/^\s+|\s+$//g;

    $line->{question} =~ s/^Q:\s+//i;
    $line->{answer}   =~ s/^A:\s+//i;

    $line->{question} = "According to $line->{book}, chapter $line->{chapter}, $line->{question}"
        if ( $line->{type} eq 'MACR' or $line->{type} eq 'CR' );
    $line->{question} = "According to $line->{book}, chapter $line->{chapter}, verse $line->{verse}, $line->{question}"
        if ( $line->{type} eq 'MACVR' or $line->{type} eq 'CVR' );

    $line->{question} = "Quote $line->{book}, chapter $line->{chapter}, verse $line->{verse}."
        if ( $line->{type} eq 'Q' );

    if ( $line->{type} eq 'Q2V' and $line->{question} =~ /(\d+)-(\d+)/ ) {
        $line->{question} = "Quote $line->{book}, chapter $line->{chapter}, verses $1 and $2.";
    }

    push( @$data, [ @$line{ qw( type book chapter verse question answer ) } ] );
}

csv( in => $data, out => $settings->{output} );

=head1 NAME

transpose_questions.pl - Load TSV questions from XLS dump and return clean CSV

=head1 SYNOPSIS

    transpose_questions.pl OPTIONS
        -i|input  INPUT_FILE
        -u|output OUTPUT_FILE
        -h|help
        -m|man

=head1 DESCRIPTION

This program will load materials data from a "dirty" or raw tab-separated values
output from Excel and return "clean" CSV. The input is expected to be in the
following order: type book chapter verse question answer. Output should be
ready to be loaded into the database.
