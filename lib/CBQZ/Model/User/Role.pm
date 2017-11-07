package CBQZ::Model::User::Role;

use Moose::Role;
use exact;
use Try::Tiny;

before [ qw( role_names roles_count has_role add_role remove_role ) ] => sub ($self) {
    E->throw('Failure because user object data not yet loaded')
        unless ( $self->obj and $self->obj->in_storage );
};

sub role_names ($self) {
    my $role_names = [ map { $_->type } $self->obj->roles->all ];
    return (wantarray) ? @$role_names : $role_names;
}

sub roles_count ($self) {
    return $self->obj->roles->count;
}

sub has_role ( $self, $role ) {
    my $roles;
    try {
        $roles = $self->roles;
    }
    catch {
        E->throw($_);
    };

    return ( grep { $_ eq $role } @{$roles} ) ? 1 : 0;
}

sub add_role ( $self, $role ) {
    $self->rs('Role')->create({
        user_id => $self->obj->id,
        type    => $role,
    });

    $self->event('role_change');
    return $self;
}

sub remove_role ( $self, $role ) {
    $self->rs('Role')->search({
        user_id => $self->obj->id,
        type    => $role,
    })->delete;

    $self->event('role_change');
    return $self;
}

1;
