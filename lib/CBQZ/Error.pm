package E {
    use Moose;
    use MooseX::ClassAttribute;
    use exact;
    use Carp 'croak';
    use Try::Tiny;
    use CBQZ;

    extends 'Throwable::Error';
    class_has cbqz => ( isa => 'CBQZ', is => 'ro', default => sub { CBQZ->new } );

    around 'throw' => sub ( $orig, $self, @params ) {
        try {
            $self->$orig(@params);
        }
        catch {
            $self->cbqz->log->log_to(
                name    => 'log_file',
                level   => 'error',
                message => ( $self->cbqz->able( $_, 'as_string' ) ) ? $_->as_string : $_,
            );

            {
                local $Carp::CarpLevel = 2;
                croak( $_->message );
            }
        };
    };

    __PACKAGE__->meta->make_immutable;
}

1;
