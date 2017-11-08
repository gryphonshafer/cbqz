package CBQZ::Model::Question;

use Moose;
use MooseX::ClassAttribute;
use exact;

extends 'CBQZ::Model';

class_has 'schema_name' => ( isa => 'Str', is => 'ro', default => 'Question' );

sub is_owned_by ( $self, $user ) {
    return (
        $user->obj->id and $self->obj->question_set->user_id and
        $user->obj->id == $self->obj->question_set->user_id
    ) ? 1 : 0;
}

__PACKAGE__->meta->make_immutable;

1;
