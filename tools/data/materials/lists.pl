#!/usr/bin/env perl
use exact;
use Config::App;
use Util::CommandLine qw( options pod2usage );
use Text::CSV_XS 'csv';
use Template;

my $settings = options( qw( input|i=s type|t=s ) );
pod2usage unless (
    $settings->{input} and $settings->{type} and (
        $settings->{type} eq 'words' or
        $settings->{type} eq 'bychapter' or
        $settings->{type} eq 'phrases'
    )
);

my ( $words, $words_by_chapter, $phrases );

for ( @{ csv( in => $settings->{input} ) } ) {
    my $verse;
    @$verse{ qw( is_para book chapter verse text ) } = @$_;
    ( $verse->{clean} = $verse->{text} ) =~ s/<[^>]*>//g;

    $verse->{words} = [
        map {
            s/(\W)'(\w.*?\w)'(\W)/$1$2$3/g;
            s/[^A-Za-z0-9'\-]/ /gi;
            s/(?<!\w)'/ /g;
            s/\-{2,}/ /g;
            s/\s+/ /g;
            s/(?:^\s|\s$)//g;
            split( /\s/, lc($_) );
        }
        map { $_ } $verse->{clean}
    ];

    my $verse_words_dedup;
    $verse_words_dedup->{$_}++ for ( @{ $verse->{words} } );
    $verse->{words_dedup} = [ sort keys %$verse_words_dedup ];

    for ( @{ $verse->{words_dedup} } ) {
        push( @{ $words->{$_} }, $verse );
        push( @{ $words_by_chapter->{ $verse->{book} . ' ' . $verse->{chapter} }{$_} }, $verse );
    }

    push( @{ $phrases->{$_} }, $verse ) for (
        map {
            join( ' ', $verse->{words}[$_], $verse->{words}[ $_ + 1 ] )
        } 0 .. @{ $verse->{words} } - 2
    );
}

my $x   = qr![^A-Za-z0-9'\-]!;
my $not = qr!$x+|$x*\-{2}$x*!;
my $tt  = Template->new;

$tt->context->define_vmethod( 'scalar', 'underline', sub {
    my $verse = $_[0];

    $verse =~ s!</span>!/\@!g;
    $verse =~ s!<span class="unique_word">!\*!g;
    $verse =~ s!<span class="unique_chapter">!\+!g;
    $verse =~ s!<span class="unique_phrase">!\^!g;

    if ( $settings->{type} eq 'phrases' ) {
        my ( $word_a, $word_b ) = split( ' ', $_[1] );

        $verse =~ s!
            ^($word_a)($not)($word_b)(?=$not)|
            ($not)($word_a)($not)($word_b)(?=$not)|
            ($not)($word_a)($not)($word_b)$
        !
            ($1) ?      '%' . $1 . $2 . $3 . '/%' :
            ($5) ? $4 . '%' . $5 . $6 . $7 . '/%' :
            ($9) ? $8 . '%' . $9 . $10 . $11 . '/%' : ''
        !iexg;
    }
    else {
        $verse =~ s!
            ^($_[1])(?=$x)|
            (?<=$x)($_[1])(?=$x)|
            (?<=$x)($_[1])$
        !
            '<u>' . ( $1 || $2 || $3 ) . '</u>'
        !iexg;
    }

    $verse =~ s!/[\*\+\^\@]!</span>!g;
    $verse =~ s!\*!<span class="unique_word">!g;
    $verse =~ s!\+!<span class="unique_chapter">!g;
    $verse =~ s!\^!<span class="unique_phrase">!g;

    $verse =~ s!/\%!</u>!g;
    $verse =~ s!\%!<u>!g;

    return $verse;
} );

$tt->process( \*DATA, {
    type => $settings->{type},
    data => (
        ( $settings->{type} eq 'words' ) ? [ map { { text => $_, verses => $words->{$_} } } sort keys %$words ] :
        ( $settings->{type} eq 'phrases' ) ? [ map { { text => $_, verses => $phrases->{$_} } } sort keys %$phrases ] : []
    ),
} );

=head1 NAME

lists.pl - Lists generation tool for a materials data file

=head1 SYNOPSIS

    lists.pl OPTIONS
        -i|input  INPUT_FILE
        -t|type   OUTPUT_TYPE (e.g. "words", "bychapter", "phrases")
        -h|help
        -m|man

=head1 DESCRIPTION

This program will generate study lists for a materials data file.

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

            h2 {
                font-size: 14px;
                margin-bottom: 0px;
            }

            p.verse {
                margin: 0px 0px 0px 75px;
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

        <title>[% type.ucfirst %] Study List</title>
    </head>
    <body>
        <h1>[% type.ucfirst %] Study List</h1>

        [% FOR item IN data %]
            <h2>[% item.text.upper %]</h2>

            [% FOR verse IN item.verses %]
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
                    [% verse.text.underline( item.text ) %]
                </p>
            [% END %]
        [% END %]
    </body>
</html>
