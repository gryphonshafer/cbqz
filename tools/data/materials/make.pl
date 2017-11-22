#!/usr/bin/env perl
use exact;
use Config::App;
use Util::CommandLine qw( options pod2usage );
use Text::CSV_XS 'csv';

my $settings = options( qw( input|i=s output|o=s ) );
pod2usage unless ( $settings->{input} and $settings->{output} );

my ( $words, $words_by_chapter, $phrases );
my $data = [ map {
    my $verse;
    @$verse{ qw( is_para book chapter verse text ) } = @$_;

    $verse->{words} = [
        map {
            $words->{$_}++;
            $_;
        }
        map {
            s/[^A-z0-9'\-]/ /g;
            s/(?<!\w)'/ /g;
            s/\-{2,}/ /g;
            s/\s+/ /g;
            s/(?:^\s|\s$)//g;
            split( /\s/, lc($_) );
        }
        map { $_ } $verse->{text}
    ];

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

$| = 1;
for my $verse (@$data) {
    for (@$unique_phrases) {
        my ( $word_a, $word_b ) = @$_;

        $verse->{text} =~ s!
            ^($word_a)
            ([^A-z0-9'\-]+|[^A-z0-9'\-]*\-\-[^A-z0-9'\-]*)
            ($word_b)
            (?=[^A-z0-9']|\-\-)
            |
            ([^A-z0-9']|\-\-)
            ($word_a)
            ([^A-z0-9'\-]+|[^A-z0-9'\-]*\-\-[^A-z0-9'\-]*)
            ($word_b)
            (?=[^A-z0-9']|\-\-)
            |
            ([^A-z0-9']|\-\-)
            ($word_a)
            ([^A-z0-9'\-]+|[^A-z0-9'\-]*\-\-[^A-z0-9'\-]*)
            ($word_b)$
        !
            ($1) ?      '<^>' . $1 . $2 .  $3  . '</^>' :
            ($5) ? $4 . '<^>' . $5 .  $6 . $7  . '</^>' :
            ($9) ? $8 . '<^>' . $9 . $10 . $11 . '</^>' : ' ~~~ERROR~~~ '
        !iex;
    }

    my $markup = sub {
        my ( $mark, $words ) = @_;

        $verse->{text} =~ s!
            ^($_)(?=[^A-z0-9'\-])
            |
            (?<=[^A-z0-9'\-])($_)(?=[^A-z0-9'\-])
            |
            (?<=[^A-z0-9'\-])($_)$
        !
            '<' . $mark . '>' . ( $1 || $2 || $3 ) . '</' . $mark . '>'
        !iex for (@$words);
    };

    $markup->( '_', $unique_words_by_chapter->{ $verse->{book} . ' ' . $verse->{chapter} } );
    $markup->( '*', $unique_words );

    $verse->{text} =~ s!<_>(<\*>)!$1!g;
    $verse->{text} =~ s!(</\*>)</_>!$1!g;

    # $verse->{text} =~ s!<\*>!<span class="unique_word">!g;
    # $verse->{text} =~ s!<_>!<span class="unique_chapter">!g;
    # $verse->{text} =~ s!<\^>!<span class="unique_phrase">!g;
    # $verse->{text} =~ s!</[\*_\^]>!</span>!g;

    print '.';
}
print "\n";

csv( in => [ map { [ @$_{ qw( is_para book chapter verse text ) } ] } @$data ], out => $settings->{output} );

=head1 NAME

make.pl - Make a materials data file from extracted output content files

=head1 SYNOPSIS

    fetch.pl OPTIONS
        -i|input INPUT_FILE
        -o|output OUTPUT_FILE
        -h|help
        -m|man

=head1 DESCRIPTION

This program will make a materials data file from extracted output content files.
