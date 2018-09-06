package CBQZ::Control::Feed;

use Mojo::Base 'Mojolicious::Controller';
use exact;

sub spike ($self) {
    $self->render( json => { answer => 42 } );

    $self->inactivity_timeout(14400); # 4 hours

    $self->socket( setup => 'spike', {
        tx => $self->tx,
        cb => sub ( $tx, $data ) {
            $tx->send( { json => { data => $data } } );
        },
    });

    $self->on( message => sub ( $self, $message ) {
        $self->socket( message => 'spike', { data => $message } );
    } );

    $self->on( finish => sub { $self->socket( finish => 'spike', { tx => $self->tx } ) } );
}

1;
