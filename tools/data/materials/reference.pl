#!/usr/bin/env perl
use exact;
use Config::App;
use Util::CommandLine qw( options pod2usage );
use Text::CSV_XS 'csv';
use Template;
use CBQZ::Util::File 'spurt';

my $settings = options( qw( input|i=s output|o=s kvl|k=s text|t ) );
pod2usage unless ( $settings->{input} );

my $kvl;
if ( $settings->{kvl} ) {
    for ( @{ csv( in => $settings->{kvl} ) } ) {
        my ( $book, $chapter, @verses ) = @$_;

        for my $verse (@verses) {
            my $key_type = ( $verse =~ /\(([^)]+)\)/ ) ? $1 : undef;
            if ( $verse =~ /^(\d+)-(\d+)/ ) {
                for ( $1 .. $2 ) {
                    $kvl->{$book}{$chapter}{$_} = { key_type => $key_type, key_class => 'range' };
                }
            }
            elsif ( $verse =~ /^(\d+)/ ) {
                $kvl->{$book}{$chapter}{$1} = { key_type => $key_type, key_class => 'solo' };
            }
        }
    }
}

my $output;
Template->new->process( \*DATA, {
    text_only => $settings->{text},
    verses    => [
        map {
            my $verse;
            @$verse{ qw( para book chapter verse text ) } = @$_;

            if ($kvl) {
                $verse->{key_class} = $kvl->{ $verse->{book} }{ $verse->{chapter} }{ $verse->{verse} }{key_class};
                $verse->{key_type}  = $kvl->{ $verse->{book} }{ $verse->{chapter} }{ $verse->{verse} }{key_type};
            }

            $verse;
        } @{ csv( in => $settings->{input} ) }
    ],
}, \$output );

if ( $settings->{output} ) {
    spurt( $settings->{output}, $output );
}
else {
    say $output;
}

=head1 NAME

reference.pl - Create a reference materials HTML file from marked-up CSV data

=head1 SYNOPSIS

    reference.pl OPTIONS
        -i|input  INPUT_FILE
        -o|output OUTPUT_FILE
        -k|kvl    KEY_VERSE_LIST_FILE
        -t|text   # verse text only in the output
        -h|help
        -m|man

=head1 DESCRIPTION

This program will create a reference materials HTML file from marked-up CSV data.

=cut

__DATA__
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name=viewport content="width=device-width, initial-scale=1">

        <style type="text/css">
            body {
                font: 13px sans-serif;
            }

            h1 {
                font-size: 20px;
                margin-top: 0px;
            }

            p.verse {
                margin: 0px 0px 0px 50px;
                text-indent: -50px;
            }

            span.reference {
                font-weight: bold;
            }

            span.para,
            span.key_markers {
                color: gray;
            }

            span.unique_word {
                font-weight: bold;
                color: blue;
            }

            span.unique_chapter {
                font-weight: bold;
                color: red;
            }

            span.unique_phrase {
                font-weight: bold;
                color: green;
            }
        </style>

        <title>Reference Material</title>
    </head>
    <body>
        <h1>Reference Material</h1>

        [% FOR verse IN verses %]
            <p class="verse">
                [% UNLESS text_only %]
                    [% IF verse.para %]<span class="para">&para;</span>[% END %]
                    <span class="reference">
                        [% verse.book %] [% verse.chapter %]:[% verse.verse %]
                    </span>
                    <span class="key_markers">
                        [% IF verse.key_class %]
                            [% IF verse.key_class == 'range' %]
                                &Dagger;
                            [% ELSE %]
                                &dagger;
                            [% END %]
                            [% verse.key_type %]
                        [% ELSE %]
                            -
                        [% END %]
                    </span>
                [% END %]
                [% verse.text %]
            </p>
        [% END %]
    </body>
</html>
