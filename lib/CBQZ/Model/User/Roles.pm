package CBQZ::Model::User::Roles;

use Moose::Role;
use Try::Tiny;

before [ qw( has_role add_role remove_role ) ] => sub {
    my ( $self, $role, $user ) = @_;

    if ($user) {
        E->throw('Input provided is not a valid user object')
            unless ( $self->able( $user, 'obj' ) and $user->obj and $user->obj->in_storage );
        E->throw('Only users with admin roles can call this method on other users')
            unless ( grep { $_->type eq 'admin' } $self->obj->roles->all );
    }
    else {
        E->throw('Failure because user object data not yet loaded')
            unless ( $self->obj and $self->obj->in_storage );
    }
};

sub roles {
    my ( $self, $user ) = @_;

    if ($user) {
        E->throw('Input provided is not a valid user object')
            unless ( $self->able( $user, 'obj' ) and $user->obj and $user->obj->in_storage );
        E->throw('Only users with admin roles can call this method on other users')
            unless ( grep { $_->type eq 'admin' } $self->obj->roles->all );
    }
    else {
        E->throw('Failure because user object data not yet loaded')
            unless ( $self->obj and $self->obj->in_storage );
    }

    my $roles = [ map { $_->type } ( ($user) ? $user : $self )->obj->roles->all ];
    return (wantarray) ? @{$roles} : $roles;
}

sub has_role {
    my ( $self, $role, $user ) = @_;

    my $roles;
    try {
        $roles = $self->roles($user);
    }
    catch {
        E->throw($_);
    };

    return ( grep { $_ eq $role } @{$roles} ) ? 1 : 0;
}

sub add_role {
    my ( $self, $role, $user ) = @_;

    $self->rs('Role')->create({
        user_id => ( ($user) ? $user : $self )->obj->id,
        type    => $role,
    });

    $self->event('role_change');
    return $self;
}

sub remove_role {
    my ( $self, $role, $user ) = @_;

    $self->rs('Role')->search({
        user_id => ( ($user) ? $user : $self )->obj->id,
        type    => $role,
    })->delete;

    $self->event('role_change');
    return $self;
}

1;
