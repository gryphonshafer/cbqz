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
pod2usage unless ( $settings->{output} );

$settings->{files} //= ['*'];

my $cbqz     = CBQZ->new;
my $data_dir = join( '/',
    $cbqz->config->get( qw( config_app root_dir ) ),
    $cbqz->config->get('data'),
    $settings->{directory} // 'html',
);

say "Processing from: $data_dir";

my $data = [];
for my $pattern ( @{ $settings->{files} } ) {
    for my $file ( <"$data_dir/$pattern"> ) {
        my $dom = Mojo::DOM->new( slurp($file) );

        my ( $book, $chapter, $verse, $is_para );
        $dom->at('div.passage-bible div.passage-content div:first-child')->children->each( sub {
            my ($node) = @_;

            if ( $node->tag eq 'h1' ) {
                my @book_chapter = split( ' ', $node->at('span.passage-display-bcv')->text );
                ( $chapter = pop @book_chapter ) =~ s/(?:^0+|\D+)//g;
                $book = join( ' ', @book_chapter );
            }
            elsif ( $node->tag eq 'h3' ) {
                $is_para = 1;
            }
            else {
                $node->find('span.text')->each( sub {
                    my ($span) = @_;

                    if ( my $chapternum = $span->at('span.chapternum') ) {
                        $chapternum->remove;
                    }

                    if ( my $versenum = $span->at('sup.versenum') ) {
                        ( $verse = $versenum->text ) =~ s/\D//g;
                        $versenum->remove;
                    }
                    else {
                        $verse //= 1,
                    }

                    my $text = unidecode( $span->all_text );
                    $text =~ s/\[[^\]]*\]//g;
                    $text =~ s/\s{2,}/ /g;
                    $text =~ s/(?:^\s+|\s+$)//g;

                    unless ( @$data and $verse and $data->[-1][3] == $verse ) {
                        push( @$data, [
                            $is_para // 1,
                            $book,
                            $chapter,
                            $verse,
                            $text,
                        ] );
                    }
                    else {
                        $data->[-1][4] .= ' ' . $text;
                    }

                    $is_para = 0;
                } );
            }
        } );

        say 'Processed: ' . substr( $file, length($data_dir) + 1 );
    }
}

csv( in => $data, out => $settings->{output} );

=head1 NAME

extract.pl - Extract materials from raw HTML content and build input files

=head1 SYNOPSIS

    extract.pl OPTIONS
        -d|directory DIRECTORY    (Optional; default: "html")
        -f|files     FILE_PATTERN (Optional; default: "*")
        -o|output    OUTPUT_FILE
        -h|help
        -m|man

=head1 DESCRIPTION

This program will extract materials from raw HTML content and build input files.
It will look for stored raw HTML in the CBQZ system's data directory under a
subdirectory defined by "directory" (which defaults to "html").

Only files matching the file pattern will be used.
