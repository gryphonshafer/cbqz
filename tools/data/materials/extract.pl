#!/usr/bin/env perl
use exact;
use Config::App;
use Util::CommandLine qw( options pod2usage );
use Mojo::DOM;
use Text::Unidecode 'unidecode';
use Text::CSV_XS 'csv';
use CBQZ;
use CBQZ::Util::File 'slurp';

my $settings = options( qw( directory|d=s files|f=s@ output|o=s ) );
pod2usage unless ( $settings->{files} and $settings->{output} );

my $cbqz     = CBQZ->new;
my $data_dir = join( '/',
    $cbqz->config->get( qw( config_app root_dir ) ),
    $cbqz->config->get('data'),
    $settings->{directory} // 'html',
);

my $data = [];
for my $pattern ( @{ $settings->{files} } ) {
    for my $file ( <"$data_dir/$pattern"> ) {
        my $dom = Mojo::DOM->new( slurp($file) );

        my @book_chapter = split( ' ', $dom->at('h1.bcv')->text );
        ( my $chapter = pop @book_chapter ) =~ s/(?:^0+|\D+)//g;
        my $book = join( ' ', @book_chapter );

        my ( $chapter_n, $is_para );
        $dom->at('div.passage-bible div.passage-content div:first-child')->find('span.text')->each( sub {
            my ($verse) = @_;

            if ( not $chapter_n and my $chapternum = $verse->at('span.chapternum') ) {
                ( $chapter_n = $chapternum->text ) =~ s/\D//g;
                $chapternum->remove;
            }

            if ( my $versenum = $verse->at('sup.versenum') ) {
                ( my $verse_n = $versenum->text ) =~ s/\D//g;
                $versenum->remove;

                my $text = unidecode( $verse->all_text );
                $text =~ s/\s*\[[^\]]*\]\s*/ /g;

                push( @$data, [
                    $is_para // 1,
                    $book,
                    $chapter,
                    $verse_n,
                    $text,
                ] );

                $is_para = 0;
            }
            else {
                $is_para = 1;
            }
        } );
    }
}

csv( in => $data, out => $settings->{output} );

=head1 NAME

extract.pl - Extract materials from raw HTML content and build input files

=head1 SYNOPSIS

    fetch.pl OPTIONS
        -d|directory
        -f|files FILE_PATTERN
        -o|output OUTPUT_FILE
        -h|help
        -m|man

=head1 DESCRIPTION

This program will extract materials from raw HTML content and build input files.
It will look for stored raw HTML in the CBQZ system's data directory under a
subdirectory defined by "directory" (which defaults to "html").

Only files matching the file pattern will be used.
