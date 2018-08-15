package CBQZ::Control::Feed;

use Mojo::Base 'Mojolicious::Controller';
use exact;

sub index ($self) {
    $self->socket( setup => 'feed_demo', $self->tx, sub {
        for (@_) {
            $_->send( { json => {
                current_time => time(),
            } } );
        }
    } );

    $self->on( message => sub { $self->socket( messsage => 'feed_demo' ) });
    $self->on( finish  => sub { $self->socket( finish   => 'feed_demo', $self->tx ) } );
}

1;
