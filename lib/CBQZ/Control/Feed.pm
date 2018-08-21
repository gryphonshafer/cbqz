package CBQZ::Control::Feed;

use Mojo::Base 'Mojolicious::Controller';
use exact;

sub spike ($self) {
    my $json = { current_time => time() };
    $self->render( json => $json );

    $self->inactivity_timeout(14400); # 4 hours
    $self->socket( setup => 'spike', $self->tx, sub { $_->send( { json => $json } ) for (@_) } );
    $self->on( message => sub { $self->socket( message => 'spike' ) });
    $self->on( finish  => sub { $self->socket( finish => 'spike', $self->tx ) } );
}

1;
