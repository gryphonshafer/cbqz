package CBQZ::Model::User::Role;

use Moose::Role;
use Try::Tiny;

before [ qw( role_names roles_count has_role add_role remove_role ) ] => sub {
    my ($self) = @_;
    E->throw('Failure because user object data not yet loaded')
        unless ( $self->obj and $self->obj->in_storage );
};

sub role_names {
    my ($self) = @_;
    my $role_names = [ map { $_->type } $self->obj->roles->all ];
    return (wantarray) ? @$role_names : $role_names;
}

sub roles_count {
    my ($self) = @_;
    return $self->obj->roles->count;
}

sub has_role {
    my ( $self, $role ) = @_;

    my $roles;
    try {
        $roles = $self->roles;
    }
    catch {
        E->throw($_);
    };

    return ( grep { $_ eq $role } @{$roles} ) ? 1 : 0;
}

sub add_role {
    my ( $self, $role ) = @_;

    $self->rs('Role')->create({
        user_id => $self->obj->id,
        type    => $role,
    });

    $self->event('role_change');
    return $self;
}

sub remove_role {
    my ( $self, $role ) = @_;

    $self->rs('Role')->search({
        user_id => $self->obj->id,
        type    => $role,
    })->delete;

    $self->event('role_change');
    return $self;
}

1;
