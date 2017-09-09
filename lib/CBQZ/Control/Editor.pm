package CBQZ::Control::Editor;

use exact;
use Mojo::Base 'Mojolicious::Controller';
use Try::Tiny;

sub save {
    my ($self) = @_;
    return $self->render( json => {
        stuff => 'things',
        data  => { answer => 'If good, this should be <span class="unique_word">blue</span>.' },
    } );
}

1;
