#!/usr/bin/env perl
use exact;
use Config::App;
use Try::Tiny;
use Util::CommandLine qw( options pod2usage );
use CBQZ::Model::Question;
use CBQZ::Model::QuestionSet;
use CBQZ::Model::MaterialSet;

my $settings = options( qw( questions|q=s materials|m=s ) );
pod2usage unless ( $settings->{questions} and $settings->{materials} );

my ( $question_set, $material_set );

try {
    $question_set = CBQZ::Model::QuestionSet->new->load({ name => $settings->{questions} });
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
for my $question ( $question_model->model( $question_set->obj->questions->all ) ) {
    $question->obj->update( $question->auto_text($material_set) );
}

=head1 NAME

markup_questions.pl - Add color markup to a plain-text questions set

=head1 SYNOPSIS

    markup_questions.pl OPTIONS
        -q|questions  QUESTIONS_SET_NAME
        -m|materials  MATERIAL_SET_NAME
        -h|help
        -m|man

=head1 DESCRIPTION

This program will add color markup to a plain-text questions set.
