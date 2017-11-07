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
