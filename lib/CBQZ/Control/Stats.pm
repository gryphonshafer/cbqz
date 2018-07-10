package CBQZ::Control::Stats;

use Mojo::Base 'Mojolicious::Controller';
use exact;
use CBQZ::Model::Quiz;

sub index ($self) {
    $self->stash(
        quizzes => [
            CBQZ::Model::Quiz->new->every_data(
                {
                    state => 'closed',
                    -or => [
                        user_id => $self->stash('user')->obj->id,
                        -and    => [
                            ( $self->stash('user')->has_role('official') ) ? (
                                official   => 1,
                                program_id => [
                                    map { $_->program->id } $self->stash('user')->obj->user_programs->all
                                ],
                            ) : 1
                        ],
                    ],
                },
            )
        ],
    );
}

1;
