use exact;
use Config::App;
use Test::Most;
use Test::Moose;
use CBQZ::Model;

use constant PACKAGE => 'CBQZ::Model::Quiz';

exit main();

sub main {
    BEGIN { use_ok(PACKAGE) }
    require_ok(PACKAGE);

    my $obj = PACKAGE->new;
    isa_ok( $obj, PACKAGE );

    can_ok( PACKAGE, $_ ) for ( qw( chapter_set generate replace ) );

    my $chapter_set;
    lives_ok(
        sub {
            $chapter_set = $obj->chapter_set(
                {
                    weight_percent    => 50,
                    weight_chapters   => 5,
                    selected_chapters => [
                        map { +{ chapter => $_, book => '1 Corinthians' } } 1 .. 16
                    ],
                }
            );
        },
        '$obj->chapter_set',
    );

    is_deeply(
        $chapter_set,
        {
            prime  =>
                '\'1 Corinthians 1\', \'1 Corinthians 2\', \'1 Corinthians 3\', \'1 Corinthians 4\', ' .
                '\'1 Corinthians 5\', \'1 Corinthians 6\', \'1 Corinthians 7\', \'1 Corinthians 8\', ' .
                '\'1 Corinthians 9\', \'1 Corinthians 10\', \'1 Corinthians 11\'',
            weight =>
                '\'1 Corinthians 16\', \'1 Corinthians 15\', \'1 Corinthians 14\', ' .
                '\'1 Corinthians 13\', \'1 Corinthians 12\'',
        },
        'chapter set data check',
    );

    if ( my $cbqz_prefs = _cbqz_prefs() ) {
        my $quiz;
        lives_ok( sub { $quiz = $obj->generate($cbqz_prefs) }, '$obj->generate' );
        ok(
            ref($quiz) eq 'HASH' &&
                ref( $quiz->{questions} ) eq 'ARRAY' &&
                @{ $quiz->{questions} } > 0 &&
                exists $quiz->{error},
            'generated quiz basic sanity check',
        );

        my $question;
        lives_ok(
            sub {
                $question = $obj->replace(
                    {
                        questions => $quiz->{questions},
                        type      => $quiz->{questions}[0]{type},
                    },
                    $cbqz_prefs,
                );
            },
            '$obj->replace',
        );
        ok(
            ref($question) eq 'ARRAY' &&
                @$question > 0 &&
                $question->[0]{type},
            'replaced question basic sanity check',
        );
    }

    done_testing();
    return 0;
};

sub _cbqz_prefs {
    my $model = CBQZ::Model->new;

    my $material_sets = $model->rs('MaterialSet')->search;
    my $programs      = $model->rs('Program')->search;
    my $question_sets = $model->rs('QuestionSet')->search;

    return unless ( $material_sets->count and $programs->count and $question_sets->count );

    my $material_set_id = $material_sets->next->id;

    return {
        material_set_id   => $material_set_id,
        program_id        => $programs->next->id,
        question_set_id   => $question_sets->next->id,
        weight_percent    => 50,
        weight_chapters   => 5,
        selected_chapters => $model->dq->sql(q{
            SELECT book, chapter
            FROM material
            WHERE material_set_id = ?
            GROUP BY 1, 2
            ORDER BY 1, 2
        })->run( $material_set_id )->all({}),
    };
}
