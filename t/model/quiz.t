use Config::App;
use Test::Most;
use Test::Moose;
use CBQZ::Model;
use exact;

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

    parse_quiz_teams_quizzers($obj);

    if ( my $cbqz_prefs = _cbqz_prefs() ) {
        my $quiz;
        lives_ok( sub { $quiz = $obj->generate($cbqz_prefs) }, '$obj->generate' );
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

sub parse_quiz_teams_quizzers ($obj) {
    my $output = [
        {
            'team' => {
                'correct' => 0,
                'incorrect' => 0,
                'name' => 'Team A',
                'score' => 0
            },
            'quizzers' => [
                {
                    'bib' => '1',
                    'incorrect' => 0,
                    'correct' => 0,
                    'name' => 'Alpha Quizzer'
                },
                {
                    'name' => 'Bravo Quizzer',
                    'incorrect' => 0,
                    'correct' => 0,
                    'bib' => '2'
                },
                {
                    'name' => 'Charlie Quizzer',
                    'incorrect' => 0,
                    'correct' => 0,
                    'bib' => '3'
                },
                {
                    'name' => 'Delta Quizzer',
                    'bib' => '4',
                    'incorrect' => 0,
                    'correct' => 0
                }
            ]
        },
        {
            'team' => {
                'correct' => 0,
                'incorrect' => 0,
                'name' => 'Team B',
                'score' => 0
            },
            'quizzers' => [
                {
                    'incorrect' => 0,
                    'correct' => 0,
                    'bib' => '1',
                    'name' => 'Echo Quizzer'
                },
                {
                    'name' => 'Foxtrot Quizzer',
                    'incorrect' => 0,
                    'correct' => 0,
                    'bib' => '2'
                },
                {
                    'correct' => 0,
                    'incorrect' => 0,
                    'bib' => '3',
                    'name' => 'Gulf Quizzer'
                },
                {
                    'name' => 'Hotel Quizzer',
                    'bib' => '4',
                    'incorrect' => 0,
                    'correct' => 0
                }
            ]
        },
        {
            'team' => {
                'name' => 'Team C',
                'score' => 0,
                'correct' => 0,
                'incorrect' => 0
            },
            'quizzers' => [
                {
                    'name' => 'India Quizzer',
                    'incorrect' => 0,
                    'correct' => 0,
                    'bib' => '1'
                },
                {
                    'name' => 'Juliet Quizzer',
                    'bib' => '2',
                    'correct' => 0,
                    'incorrect' => 0
                },
                {
                    'name' => 'Kilo Quizzer',
                    'incorrect' => 0,
                    'correct' => 0,
                    'bib' => '3'
                },
                {
                    'bib' => '4',
                    'correct' => 0,
                    'incorrect' => 0,
                    'name' => 'Lima Quizzer'
                }
            ]
        }
    ];

    is_deeply(
        $obj->parse_quiz_teams_quizzers(
            "Team A\n1. Alpha Quizzer\n2. Bravo Quizzer\n3. Charlie Quizzer\n4. Delta Quizzer\n\n" .
            "Team B\n1. Echo Quizzer\n2. Foxtrot Quizzer\n3. Gulf Quizzer\n4. Hotel Quizzer\n\n" .
            "Team C\n1. India Quizzer\n2. Juliet Quizzer\n3. Kilo Quizzer\n4. Lima Quizzer\n"
        ),
        $output,
        'parse_quiz_teams_quizzers basic input',
    );

    is_deeply(
        $obj->parse_quiz_teams_quizzers(
            "\n\n   Team A\n   1.    Alpha Quizzer     \n2. Bravo Quizzer\n3. Charlie Quizzer\n4. Delta Quizzer\n\n" .
            "Team B\n1. Echo Quizzer\n2. Foxtrot Quizzer\n3. Gulf Quizzer\n4. Hotel Quizzer\n\n    \n\n" .
            "Team C\n1. India Quizzer\n2. Juliet Quizzer\n3. Kilo Quizzer\n4. Lima Quizzer\n"
        ),
        $output,
        'parse_quiz_teams_quizzers basic input',
    );
}
