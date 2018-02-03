package CBQZ::Model::User::Program;

use Moose::Role;
use exact;
use Try::Tiny;
use CBQZ::Model::Program;

before [ qw( programs programs_count add_program remove_program ) ] => sub {
    my ($self) = @_;
    E->throw('Failure because user object data not yet loaded')
        unless ( $self->obj and $self->obj->in_storage );
};

sub programs ($self) {
    my $programs = CBQZ::Model::Program->new->model( map { $_->program } $self->obj->user_programs->all );
    return (wantarray) ? @$programs : $programs;
}

sub programs_count ($self) {
    return $self->obj->user_programs->count;
}

sub add_program ( $self, $program_id ) {
    $self->rs('UserProgram')->create({
        user_id    => $self->obj->id,
        program_id => $program_id,
    });

    return $self;
}

sub remove_program ( $self, $program_id ) {
    $self->rs('UserProgram')->search({
        user_id    => $self->obj->id,
        program_id => $program_id,
    })->delete;

    return $self;
}

1;
