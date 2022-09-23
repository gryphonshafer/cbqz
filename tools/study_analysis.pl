#!/usr/bin/env perl
use exact -conf;
use CBQZ::Model::Quiz;
use CBQZ::Model::Program;

my $quizzes       = 10_000;
my $quizzes_per   = 16;
my $questions_per = 22;
my $cbqz_prefs    = {
    program_id        => 1,
    material_set_id   => 17,
    question_set_id   => 977,
    randomize_first   => 20,
    target_questions  => 40,
    weight_percent    => 50,
    weight_chapters   => 0,
    selected_chapters => [ map { +{ book => 'Acts', chapter => $_ } } 1 .. 6 ],
    question_types    =>
        "INT: 8-14 (INT)\n" .
        "MA: 1-2 (MA)\n" .
        "Ref: 3-6 (CR CVR MACR MACVR)\n" .
        "Q: 2-3 (Q Q2V)\n" .
        "F: 3-4 (FT FTN FTV F2V)\n" .
        "SIT: 2-4 (SIT)\n",
};

$| = 1;

my $obj = CBQZ::Model::Quiz->new;

my $reset = $obj->dq->sql( 'UPDATE question SET used = 0 WHERE question_set_id = ' . $cbqz_prefs->{question_set_id} );
my $use   = $obj->dq->sql('UPDATE question SET used = used + 1 WHERE question_id = ?');

$reset->run;

my @questions;
for ( 1 .. $quizzes ) {
    $reset->run unless ( $_ % $quizzes_per );
    my $quiz = $obj->generate($cbqz_prefs);
    print '.';
    for my $question ( map { $quiz->[$_] } 1 .. $questions_per ) {
        $use->run( $question->{question_id} );
        push( @questions, $question );
    }
}

print "\n";

my $refs_count;
$refs_count->{ $_->{chapter} . '_' . $_->{verse} }++ for (@questions);

open( my $out, '>', 'analysis.csv' );

print $out join( ',', @$_ ) . "\n" for (
    map { [ $_->[0], $refs_count->{ $_->[0] } ] }
    sort { $a->[1] <=> $b->[1] || $a->[2] <=> $b->[2] }
    map { [ $_, split(/_/) ] }
    keys %$refs_count
);
