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

            $context->define_vmethod( 'scalar', 'commify', sub {
                return scalar( reverse join( ',', unpack( '(A3)*', scalar( reverse $_[0] ) ) ) );
            } );

            $context->define_vmethod( 'list', 'sort_by', sub {
                my ( $arrayref, $sort_by, $sort_order ) = @_;
                return $arrayref unless ($sort_by);

                return [ sort {
                    my ( $c, $d ) = ( $a, $b );
                    ( $c, $d ) = ( $d, $c ) if ( $sort_order and $sort_order eq 'desc' );

                    ( $c->{$sort_by} =~ /^\d+$/ and $d->{$sort_by} =~ /^\d+$/ )
                        ? $c->{$sort_by} <=> $d->{$sort_by}
                        : $c->{$sort_by} cmp $d->{$sort_by}
                } @$arrayref ];
            } );
        },
    };
}

1;
