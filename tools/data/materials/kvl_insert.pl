#!/usr/bin/env perl
use exact;
use open qw( :std :utf8 );
use Util::CommandLine qw( options pod2usage );
use Text::CSV_XS 'csv';

my $settings = options( qw( kvl|k=s input|i=s output|o=s filter|f ) );
pod2usage unless ( $settings->{kvl} and $settings->{input} and $settings->{output} );

my $kvl;
for ( @{ csv( in => $settings->{kvl} ) } ) {
    my ( $book, $chapter, @verses ) = @$_;

    for my $verse (@verses) {
        my $key_type = ( $verse =~ /\(([^)]+)\)/ ) ? $1 : undef;
        if ( $verse =~ /^(\d+)-(\d+)/ ) {
            for ( $1 .. $2 ) {
                $kvl->{$book}{$chapter}{$_} = { key_type => $key_type, key_class => 'Range' };
            }
        }
        elsif ( $verse =~ /^(\d+)/ ) {
            $kvl->{$book}{$chapter}{$1} = { key_type => $key_type, key_class => 'Single' };
        }
    }
}

my $buffer;
my $data = [
    grep { defined }
    map {
        my $verse;
        @$verse{ qw( para book chapter verse text ) } = @$_;

        unless (
            $kvl->{ $verse->{book} }{ $verse->{chapter} }{ $verse->{verse} }{key_class} and
            $kvl->{ $verse->{book} }{ $verse->{chapter} }{ $verse->{verse} }{key_class} eq 'Range'
        ) {
            [
                $kvl->{ $verse->{book} }{ $verse->{chapter} }{ $verse->{verse} }{key_class},
                $kvl->{ $verse->{book} }{ $verse->{chapter} }{ $verse->{verse} }{key_type},
                @$verse{ qw( book chapter verse text ) },
            ];
        }
        elsif ( not $buffer ) {
            $buffer = [
                $kvl->{ $verse->{book} }{ $verse->{chapter} }{ $verse->{verse} }{key_class},
                $kvl->{ $verse->{book} }{ $verse->{chapter} }{ $verse->{verse} }{key_type},
                $verse->{book},
                $verse->{chapter},
                q( ) . $verse->{verse},
                $verse->{text},
            ];
            undef;
        }
        else {
            my $this = $buffer;
            undef $buffer;
            $this->[4] .= '-' . $verse->{verse};
            $this->[5] .= ' ' . $verse->{text};
            $this;
        }
    } @{ csv( in => $settings->{input} ) }
];

$data = [ grep { $_->[0] } @$data ] if ( $settings->{filter} );

csv( in => $data, out => $settings->{output} );

=head1 NAME

kvl_insert.pl - Insert key verse list column into materials CSV

=head1 SYNOPSIS

    kvl_insert.pl OPTIONS
        -k|kvl     KEY_VERSE_LIST_DATA_FILE
        -i|input   INPUT_MATERIAL_DATA_FILE
        -o|output  OUTPUT_MATERIAL_DATA_FILE
        -f|filter  (filters out non-key verses)
        -h|help
        -m|man
