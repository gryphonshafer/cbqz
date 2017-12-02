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

package E::Db {
    use Moose;
    extends 'E';

    has sql => ( is => 'ro' );

    __PACKAGE__->meta->make_immutable;
}

1;

=head1 NAME

CBQZ::Error

=head1 SYNOPSIS

    use CBQZ;

    E->throw('Generic error');
    E::Db->throw('Database error');

=head1 DESCRIPTION

This module sets up throwing exceptions. You can throw exceptions as objects
that you can catch up the chain or ignore and they'll be properly logged and
all that jazz.

You shouldn't use this module directly, since it's loaded with the CBQZ base
class.

Throw objects with C<throw>. See L<Throwable::Error> documentation for
additional details.

=head1 ERROR CLASSES

The following are the current error classes: C<E> and C<E:Db>.
