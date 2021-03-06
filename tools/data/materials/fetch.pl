#!/usr/bin/env perl
use exact;
use Config::App;
use Util::CommandLine qw( options pod2usage );
use File::Path 'make_path';
use Encode 'decode_utf8';
use CBQZ;
use CBQZ::Util::File 'spurt';

my $settings = options( qw( books|b=s@ directory|d=s version|v=s ) );
pod2usage unless ( $settings->{books} );

my $cbqz     = CBQZ->new;
my $data_dir = join( '/',
    $cbqz->config->get( qw( config_app root_dir ) ),
    $cbqz->config->get('data'),
    $settings->{directory} // 'html',
);

$settings->{version} //= 'NIV';

say "Saving to: $data_dir";

for my $book ( @{ $settings->{books} } ) {
    my $chapter = 1;
    while (1) {
        my $result = $cbqz->ua->get(
            'https://www.biblegateway.com/passage/' .
                '?version=' . uc( $settings->{version} ) .
                '&search=' . join( ' ', $book, $chapter )
        )->result;

        last unless (
            $result->is_success and
            not $result->dom->find('h3')
                ->map( sub { $_->text } )
                ->grep( sub { $_[0] eq 'No results found.' } )
                ->size
        );

        my $title  = join( ' ', $book, sprintf( '%03d', $chapter ) );
        $title =~ tr/ /_/;

        spurt( $data_dir . '/' . $title . '.html', decode_utf8( $result->body ) );

        say $book, ' ', $chapter, ' => ', $title . '.html';
        $chapter++;
    }
}

=head1 NAME

fetch.pl - Fetch materials raw HTML content

=head1 SYNOPSIS

    fetch.pl OPTIONS
        -b|books      BOOK_NAMES   (i.e. "1 Corinthians")
        -d|directory  DIRECTORY    (Optional; default: "html")
        -v|version    VERSION      (Optional; default: "NIV")
        -h|help
        -m|man

=head1 DESCRIPTION

This program will fetch materials raw HTML content. It will store the HTML
result files (1 file per chapter of books provided) in the CBQZ system's data
directory under a subdirectory defined by the "directory" value (which defaults
to "html").

    ./fetch.pl -b '1 Corinthians' -b '2 Corinthians'
