package CBQZ::Model::QuizQuestion;

use Moose;
use MooseX::ClassAttribute;
use exact;

extends 'CBQZ::Model';

class_has 'schema_name' => ( isa => 'Str', is => 'ro', default => 'QuizQuestion' );

__PACKAGE__->meta->make_immutable;

1;
