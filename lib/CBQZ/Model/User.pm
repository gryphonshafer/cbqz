package CBQZ::Model::User;

use Moose;
use MooseX::ClassAttribute;
use Digest::SHA 'sha256_hex';
use Try::Tiny;
use CBQZ::Model::QuestionSet;

extends 'CBQZ::Model';

with 'CBQZ::Model::User::PreLogin';
with 'CBQZ::Model::User::Roles';

class_has 'schema_name' => ( isa => 'Str', is => 'ro', default => 'User' );

before [ qw( change_name change_passwd ) ] => sub {
    my ($self) = @_;
    E->throw('Failure because user object data not yet loaded')
        unless ( $self->obj and $self->obj->in_storage );
};

sub password_quality {
    my ( $self, $passwd ) = @_;
    return ( $passwd and length $passwd >= 6 ) ? 1 : 0;
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

sub programs {
    my ( $self, $user ) = @_;

    if ($user) {
        E->throw('Input provided is not a valid user object')
            unless ( $self->able( $user, 'obj' ) and $user->obj and $user->obj->in_storage );
    }
    else {
        E->throw('Failure because user object data not yet loaded')
            unless ( $self->obj and $self->obj->in_storage );
    }

    my $programs = [ map { $_->program } ( ($user) ? $user : $self )->obj->user_programs->all ];
    return (wantarray) ? @{$programs} : $programs;
}

sub add_program {
    my ( $self, $program_id, $user ) = @_;

    $self->rs('UserProgram')->create({
        user_id    => ( ($user) ? $user : $self )->obj->id,
        program_id => $program_id,
    });

    return $self;
}

sub remove_program {
    my ( $self, $program_id, $user ) = @_;

    $self->rs('UserProgram')->search({
        user_id    => ( ($user) ? $user : $self )->obj->id,
        program_id => $program_id,
    })->delete;

    return $self;
}

sub question_sets {
    my ($self) = @_;

    E->throw('Failure because user object data not yet loaded')
        unless ( $self->obj and $self->obj->in_storage );

    my $question_sets = [ map {
        my $set = CBQZ::Model::QuestionSet->new;
        $set->obj($_);
        $set;
    } $self->obj->question_sets->all ];

    $question_sets = [ CBQZ::Model::QuestionSet->new->create_default( $self->stash('user') ) ]
        unless (@$question_sets);

    return $question_sets;
}

__PACKAGE__->meta->make_immutable;

1;
