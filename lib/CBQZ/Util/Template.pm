package CBQZ::Util::Template;

use exact;

require Exporter;

our @ISA       = 'Exporter';
our @EXPORT_OK = 'tt_settings';

sub tt_settings ( $type, $tt_conf, $constants ) {
    return {
        config => {
            INCLUDE_PATH => $tt_conf->{$type}{include_path},
            COMPILE_EXT  => $tt_conf->{compile_ext},
            COMPILE_DIR  => $tt_conf->{compile_dir},
            WRAPPER      => $tt_conf->{$type}{wrapper},
            CONSTANTS    => $constants || {},
            FILTERS => {
                ucfirst => sub { return ucfirst shift },
                round   => sub { return int( $_[0] + 0.5 ) },
            },
            ENCODING => 'utf8',
        },
        context => sub {
            my ($context) = @_;

            $context->define_vmethod( 'scalar', 'lower',   sub { return lc( $_[0] ) } );
            $context->define_vmethod( 'scalar', 'upper',   sub { return uc( $_[0] ) } );
            $context->define_vmethod( 'scalar', 'ucfirst', sub { return ucfirst( lc( $_[0] ) ) } );

            $context->define_vmethod( $_, 'ref', sub { return ref( $_[0] ) } )
                for ( qw( scalar list hash ) );
        },
    };
}

1;
