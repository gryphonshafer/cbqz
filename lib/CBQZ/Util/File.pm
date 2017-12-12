package CBQZ::Util::File;

use exact;
use Mojo::File 'path';
use IO::All '-utf8';

require Exporter;

our @ISA       = 'Exporter';
our @EXPORT_OK = qw( filename slurp spurt );

sub filename (@filenames) {
    return join( '/', map {
        my $node = $_ || '';
        $node =~ s/\s+/_/g;
        $node =~ s/["':;+=|{}\[\]\\]+//g;
        lc($node);
    } @filenames );
}

sub slurp ($file) {
    my $path =
        ( ref $file eq 'ARRAY'      ) ? path( filename(@$file) ) :
        ( ref $file eq 'Mojo::File' ) ? $file                    : path($file);

    return scalar( io($path)->slurp );
}

sub spurt ( $file, $data ) {
    my $path =
        ( ref $file eq 'ARRAY'      ) ? path( filename(@$file) ) :
        ( ref $file eq 'Mojo::File' ) ? $file                    : path($file);

    $path->dirname->make_path;
    $data > io($path);

    return;
}

1;

=head1 NAME

CBQZ::Util::File

=head1 SYNOPSIS

    use exact;
    use CBQZ::Util::File qw( filename slurp spurt );

    say filename( 'Things:', 'And+', 'Stuff;' );
    # returns: "things/and/stuff"

    my $file_content = slurp('file.txt');
    spurt( 'file.txt', $file_content );

=head1 DESCRIPTION

This class offers some methods for optional export that are related to files.
Nothing is exported by default.

=head1 METHODS

=head2 filename

Accepts a list of strings and returns them concatinated together in a path and
filename that's mostly reasonable.

    say filename( 'Things:', 'And+', 'Stuff;' );
    # returns: "things/and/stuff"

=head2 slurp

Slurps up a file's contents and returns it as a scalar.

    my $file_content = slurp('file.txt');

=head2 spurt

Saves scalar string content into a file.

    spurt( 'file.txt', $file_content );
