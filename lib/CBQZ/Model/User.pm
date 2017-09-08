package CBQZ::Model::User;

use Moose;
use MooseX::ClassAttribute;
use Digest::SHA 'sha256_hex';
use Try::Tiny;

extends 'CBQZ::Model';

with 'CBQZ::Model::User::PreLogin';

class_has 'schema_name' => ( isa => 'Str', is => 'ro', default => 'User' );

before [ qw( change_name change_passwd ) ] => sub {
    my ($self) = @_;
    E->throw('Failure because user object data not yet loaded')
        unless ( $self->obj and $self->obj->in_storage );
};

sub password_quality {
    my ( $self, $passwd ) = @_;
    return (
        $passwd and
        length $passwd >= 8 and
        $passwd =~ /[A-Z]/ and
        $passwd =~ /[a-z]/ and
        $passwd =~ /[0-9]/ and
        $passwd =~ /[^A-Za-z0-9]/
    ) ? 1 : 0;
}

sub change_name {
    my ( $self, $name, $underscore_ok ) = @_;

    E->throw('"name" not defined in input') unless ($name);
    E->throw('"name" length < 6 in input') if ( length $name < 6 );

    E->throw('"name" cannot begin with _') if (
        not $underscore_ok and
        index( $name, '_' ) == 0
    );

    try {
        $self->obj->update({ name => $name });
    }
    catch {
        E->throw('Failed to rename user; name already in use' )
            if ( index( $_, 'Duplicate entry' ) > -1 );
        E->throw($_);
    };

    return $self->obj;
}

sub change_passwd {
    my ( $self, $passwd, $old_passwd ) = @_;
    E->throw('Password complexity not met') unless ( $passwd and $self->password_quality($passwd) );

    E->throw('Password provided does not match stored password')
        if ( defined $old_passwd and $self->obj->passwd ne sha256_hex($old_passwd) );

    return $self->obj->update({ passwd => $passwd });
}

sub event {
    my ( $self, $type, $user_id ) = @_;

    $self->rs('Event')->create({
        user_id  => $user_id || $self->obj->id,
        type     => $type,
    });

    return;
}

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

    return $self;
}

sub remove_role {
    my ( $self, $role, $user ) = @_;

    $self->rs('Role')->search({
        user_id => ( ($user) ? $user : $self )->obj->id,
        type    => $role,
    })->delete;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
