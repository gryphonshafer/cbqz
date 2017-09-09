package CBQZ::Control::Editor;

use exact;
use Mojo::Base 'Mojolicious::Controller';
use Try::Tiny;

sub data {
    my ($self) = @_;
    $self->stash( 'skip_wrapper' => 1 );
}

sub save {
    my ($self) = @_;

    my $data = $self->req_body_json;
    $data->{verse}  = 42;
    $data->{answer} = 'This is <span class="unique_word">blue</span>. This is <span class="unique_phrase">special green</span>.';

    return $self->render( json => {
        question => $data,
    } );
}

1;
