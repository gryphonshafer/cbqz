package CBQZ::Control::Stats;

use Mojo::Base 'Mojolicious::Controller';
use exact;
use CBQZ::Model::Quiz;

sub index ($self) {
    my $get_quiz_data = sub {
        return [
            CBQZ::Model::Quiz->new->every_data(
                {
                    state => $_[0],
                    -or   => [
                        user_id => $self->stash('user')->obj->id,
                        -and    => [
                            official   => 1,
                            program_id => [
                                map { $_->program->id } $self->stash('user')->obj->user_programs->all
                            ],
                        ],
                    ],
                },
                {
                    order_by => { -desc => 'last_modified' },
                },
            )
        ];
    };

    $self->stash(
        quizzes => {
            active => $get_quiz_data->('active'),
            closed => $get_quiz_data->('closed'),
        },
    );
}

sub quiz ($self) {
    my $quiz    = CBQZ::Model::Quiz->new;
    my $quizzes = $quiz->rs->search(
        {
            quiz_id => $self->param('id'),
            -or     => [
                user_id => $self->stash('user')->obj->id,
                -and    => [
                    official   => 1,
                    program_id => [
                        map { $_->program->id } $self->stash('user')->obj->user_programs->all
                    ],
                ],
            ],
        }
    );

    unless ( $quizzes->count ) {
        $self->flash( message =>
            q{It appears you do not have access to view this particular quiz's data.}
        );
        return $self->redirect_to('/stats');
    }

    $quiz->obj( $quizzes->first );

    my $quiz_data = $quiz->data;
    $quiz_data->{$_} = $self->cbqz->json->decode( $quiz_data->{$_} ) for ( qw( metadata questions ) );

    $self->stash(
        quiz   => $quiz_data,
        events => [
            CBQZ::Model::QuizQuestion->new->every_data(
                { quiz_id => $quiz->obj->id },
                { order_by => 'created' },
            )
        ],
    );
}

1;
