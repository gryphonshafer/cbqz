package CBQZ::Model::User::Role;

use Moose::Role;
use exact;

before [ qw( roles has_role has_any_role_in_program add_role remove_role ) ] => sub {
    my ($self) = @_;
    E->throw('Failure because user object data not yet loaded')
        unless ( $self->obj and $self->obj->in_storage );
};

sub roles ( $self, $role_name = undef, $program_id = undef ) {
    my $roles = [
        grep { ($role_name) ? $_->type eq $role_name : 1 }
        grep { ($program_id) ? $_->program_id && $_->program_id == $program_id : 1 }
        $self->obj->roles->all
    ];

    return (wantarray) ? @$roles : $roles;
}

sub has_role ( $self, $role_name = undef, $program_id = undef ) {
    return ( @{ $self->roles( $role_name, $program_id ) } ) ? 1 : 0;
}

sub has_any_role_in_program ( $self, $program_id = undef ) {
    return ( @{ $self->roles( undef, $program_id ) } ) ? 1 : 0;
}

sub add_role ( $self, $role_name, $program_id ) {
    $self->rs('Role')->create({
        user_id    => $self->obj->id,
        program_id => $program_id,
        type       => $role_name,
    });

    $self->event('role_change');
    return $self;
}

sub remove_role ( $self, $role_name, $program_id ) {
    $self->rs('Role')->search({
        user_id    => $self->obj->id,
        program_id => $program_id,
        type       => $role_name,
    })->delete;

    $self->event('role_change');
    return $self;
}

1;
