package CBQZ::Control::Feed;

use Mojo::Base 'Mojolicious::Controller';
use exact;

sub index ($self) {
    my $json = {
        current_time => time(),
    };

    $self->socket( setup => 'feed_demo', $self->tx, sub { $_->send( { json => $json } ) for (@_) } );
    $self->on( message => sub { $self->socket( messsage => 'feed_demo' ) });
    $self->on( finish  => sub { $self->socket( finish   => 'feed_demo', $self->tx ) } );
    $self->render( json => $json );
}

1;
