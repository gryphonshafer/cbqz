package CBQZ::Model::User;

use Moose;
use MooseX::ClassAttribute;
use exact;
use Digest::SHA 'sha256_hex';
use Try::Tiny;
use CBQZ::Model::QuestionSet;

extends 'CBQZ::Model';

with 'CBQZ::Model::User::PreLogin';
with 'CBQZ::Model::User::Role';
with 'CBQZ::Model::User::Program';

class_has 'schema_name' => ( isa => 'Str', is => 'ro', default => 'User' );

before [ qw( change_name change_passwd ) ] => sub ($self) {
    E->throw('Failure because user object data not yet loaded')
        unless ( $self->obj and $self->obj->in_storage );
};

sub password_quality ( $self, $passwd ) {
    return ( $passwd and length $passwd >= 6 ) ? 1 : 0;
}

sub change_name ( $self, $name, $underscore_ok = 0 ) {
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

sub change_passwd ( $self, $passwd, $old_passwd ) {
    E->throw('Password complexity not met') unless ( $passwd and $self->password_quality($passwd) );
    E->throw('Password provided does not match stored password')
        if ( defined $old_passwd and $self->obj->passwd ne sha256_hex($old_passwd) );

    return $self->obj->update({ passwd => $passwd });
}

sub event ( $self, $type, $user_id = undef ) {
    $self->rs('Event')->create({
        user_id  => $user_id || $self->obj->id,
        type     => $type,
    });

    return;
}

sub question_sets ($self) {
    E->throw('Failure because user object data not yet loaded')
        unless ( $self->obj and $self->obj->in_storage );

    my $question_sets = CBQZ::Model::QuestionSet->new->model( $self->obj->question_sets->all );
    $question_sets = [ CBQZ::Model::QuestionSet->new->create($self) ]
        unless (@$question_sets);

    return (wantarray) ? @$question_sets : $question_sets;
}

__PACKAGE__->meta->make_immutable;

1;
