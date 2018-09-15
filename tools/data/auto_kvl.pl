#!/usr/bin/env perl
use exact;
use Config::App;
use Try::Tiny;
use Util::CommandLine qw( options pod2usage );
use CBQZ::Model::MaterialSet;
use CBQZ::Model::QuestionSet;

my $settings = options( qw( questions|q=s materials|m=s ) );
pod2usage unless ( $settings->{questions} and $settings->{materials} );

my $material_set;
try {
    $material_set = CBQZ::Model::MaterialSet->new->load( { 'name' => $settings->{materials} } );
}
catch {
    die "Unable to load material set\n";
};

my $question_set;
try {
    $question_set = CBQZ::Model::QuestionSet->new->load( { 'name' => $settings->{questions} } );
}
catch {
    die "Unable to load question set\n";
};

$question_set->auto_kvl($material_set);

=head1 NAME

auto_kvl.pl - Run the Auto-KVL functionality against a question set

=head1 SYNOPSIS

    auto_kvl.pl OPTIONS
        -q|questions  QUESTION_SET_NAME
        -m|materials  MATERIAL_SET_NAME
        -h|help
        -m|man

=head1 DESCRIPTION

This program will run the "auto-KVL" functionality against a given questions
set.
