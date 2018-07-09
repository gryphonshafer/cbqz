#!/usr/bin/env perl
use exact;
use Config::App;
use Try::Tiny;
use Util::CommandLine qw( options pod2usage );
use Progress::Any;
use Progress::Any::Output;
use CBQZ;
use CBQZ::Model::Question;
use CBQZ::Model::QuestionSet;
use CBQZ::Model::MaterialSet;

my $settings = options( qw( user|u=s questions|q=s materials|m=s ) );
pod2usage unless ( $settings->{user} and $settings->{questions} and $settings->{materials} );

my ( $question_set, $material_set );

my $user_id = CBQZ->new->dq->sql('SELECT user_id FROM user WHERE username = ?')->run( $settings->{user} )->value;
die "Failed to find user $settings->{user}\n" unless ($user_id);

try {
    $question_set = CBQZ::Model::QuestionSet->new->load({
        name    => $settings->{questions},
        user_id => $user_id,
    });
}
catch {
    die "Failed to load question set\n";
};

try {
    $material_set = CBQZ::Model::MaterialSet->new->load({ name => $settings->{materials} });
}
catch {
    die "Failed to load material set\n";
};

my $question_model = CBQZ::Model::Question->new;

my $count = $question_set->obj->questions->count;
say "Processing $count questions...";

my $progress = Progress::Any->get_indicator( task => 'questions', target => $count );
Progress::Any::Output->set( { task => 'questions' }, 'TermProgressBarColor' );

for my $question ( $question_model->model( $question_set->obj->questions->all ) ) {
    my $data = $question->auto_text($material_set);

    if ( $data->{error} ) {
        warn sprintf(
            "%s on question ID %s; %s %s:%s\n",
            map { $data->{$_} } qw( error question_id book chapter verse )
        );

        $data->{marked} = delete $data->{error};
    }

    $question->obj->update($data);
    $progress->update;
}

$progress->finish;

=head1 NAME

markup_questions.pl - Add color markup to a plain-text questions set

=head1 SYNOPSIS

    markup_questions.pl OPTIONS
        -u|user       USERNAME
        -q|questions  QUESTIONS_SET_NAME
        -m|materials  MATERIAL_SET_NAME
        -h|help
        -m|man

=head1 DESCRIPTION

This program will add color markup to a plain-text questions set.
