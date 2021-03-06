#!/usr/bin/env perl
use exact;
use Config::App;
use Util::CommandLine qw( options pod2usage );
use Text::CSV_XS 'csv';
use Progress::Any;
use Progress::Any::Output;

my $settings = options( qw( input|i=s output|o=s ) );
pod2usage unless ( $settings->{input} and $settings->{output} );

my ( $words, $words_by_chapter, $phrases );
my $data = [ map {
    my $verse;
    @$verse{ qw( is_para book chapter verse text ) } = @$_;

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
        map { $_ } $verse->{text}
    ];

    my $verse_words_dedup;
    $verse_words_dedup->{$_}++ for ( @{ $verse->{words} } );
    $verse->{words_dedup} = [ sort keys %$verse_words_dedup ];
    $words->{$_}++ for ( @{ $verse->{words_dedup} } );

    $words_by_chapter->{ $verse->{book} . ' ' . $verse->{chapter} }{$_}++ for ( @{ $verse->{words} } );

    push( @$phrases,
        map {
            [ $verse->{words}[$_], $verse->{words}[ $_ + 1 ] ]
        } 0 .. @{ $verse->{words} } - 2
    );

    $verse;
} @{ csv( in => $settings->{input} ) } ];

my $unique_words = [ grep { $words->{$_} == 1 } keys %$words ];

my $unique_words_by_chapter = { map {
    my $chapter = $_;
    $chapter => [
        grep { $words_by_chapter->{$chapter}{$_} == 1 } keys %{ $words_by_chapter->{$chapter} }
    ];
} keys %$words_by_chapter };

my $phrases_map;
for ( map { [ join( ' ', @$_ ), $_ ] } @$phrases ) {
    unless ( $phrases_map->{ $_->[0] } ) {
        $phrases_map->{ $_->[0] } = {
            set   => $_->[1],
            count => 1,
        };
    }
    else {
        $phrases_map->{ $_->[0] }{count}++;
    }
}
my $unique_phrases = [
    map { $phrases_map->{$_}{set} } grep { $phrases_map->{$_}{count} == 1 } keys %$phrases_map
];

my $x   = qr![^A-Za-z0-9'\-]!;
my $not = qr!$x+|$x*\-{2}$x*!;

my $progress = Progress::Any->get_indicator( task => 'data', target => scalar(@$data) );
Progress::Any::Output->set( { task => 'data' }, 'TermProgressBarColor' );

say 'Processing ', scalar(@$data), ' verses...';

for my $verse (@$data) {
    $verse->{text} =~ s!^'!~!g;
    $verse->{text} =~ s!'$!~!g;
    $verse->{text} =~ s!'([^A-Za-z])!~$1!g;
    $verse->{text} =~ s!([^A-Za-z])'!$1~!g;

    for (@$unique_phrases) {
        my ( $word_a, $word_b ) = @$_;

        $verse->{text} =~ s!
            ^($word_a)($not)($word_b)(?=$not)|
            ($not)($word_a)($not)($word_b)(?=$not)|
            ($not)($word_a)($not)($word_b)$
        !
            ($1) ?      '^' . $1 . '/^' .  $2 . '^' .  $3 . '/^' :
            ($5) ? $4 . '^' . $5 . '/^' .  $6 . '^' .  $7 . '/^' :
            ($9) ? $8 . '^' . $9 . '/^' . $10 . '^' . $11 . '/^' : ''
        !iexg;
    }

    $verse->{text} =~ s!\^{2,}!\^!g;
    $verse->{text} =~ s!(?:/\^){2,}!/\^!g;

    my $markup = sub {
        my ( $mark, $words ) = @_;

        for (@$words) {
            $verse->{text} =~ s!
                ^($_)(?=$x)|
                (?<=$x)($_)(?=$x)|
                (?<=$x)($_)$
            !
                $mark . ( $1 || $2 || $3 ) . '/' . $mark
            !iexg;
        }
    };

    $markup->( '+', $unique_words_by_chapter->{ $verse->{book} . ' ' . $verse->{chapter} } );
    $markup->( '*', $unique_words );

    $verse->{text} =~ s!/[\*\+\^]!</span>!g;
    $verse->{text} =~ s!\*!<span class="unique_word">!g;
    $verse->{text} =~ s!\+!<span class="unique_chapter">!g;
    $verse->{text} =~ s!\^!<span class="unique_phrase">!g;

    $verse->{text} =~ s!~!'!g;

    $progress->update;
}

$progress->finish;

csv( in => [ map { [ @$_{ qw( is_para book chapter verse text ) } ] } @$data ], out => $settings->{output} );

=head1 NAME

markup.pl - Markup a materials data file from extracted output content files

=head1 SYNOPSIS

    markup.pl OPTIONS
        -i|input  INPUT_FILE
        -o|output OUTPUT_FILE
        -h|help
        -m|man

=head1 DESCRIPTION

This program will markup a materials data file from extracted output content files.
