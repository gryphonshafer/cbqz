package CBQZ::Control::Feed;

use Mojo::Base 'Mojolicious::Controller';
use exact;

sub not_working_hypnotoad_spike ($self) {
    my $json = {
        current_time => time(),
    };

    $self->socket( setup => 'feed_demo', $self->tx, sub { $_->send( { json => $json } ) for (@_) } );
    $self->on( message => sub { $self->socket( messsage => 'feed_demo' ) });
    $self->on( finish  => sub { $self->socket( finish   => 'feed_demo', $self->tx ) } );
}

{
    my %subscribers;
    sub working_morbo_spike ($self) {
        $subscribers{$self} = $self;

        $self->on( message => sub ( $self, $message ) {
            $_->send( $message . '|' . time() ) for values %subscribers;
        } );

        $self->on( finish => sub ( $self, @ ) { delete $subscribers{$self} } );

        $self->render( json => { current_time => time() } );
    }
}

1;
