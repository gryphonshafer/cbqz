package CBQZ::Db::Base::Result::User;

use Moose::Role;
use Digest::SHA 'sha256_hex';

around set_column => sub {
    my ( $code, $self, $name, $value, $seen ) = @_;
    $value = sha256_hex($value) if ( not $seen and $name eq 'passwd' );
    return $self->$code( $name, $value, 1 );
};

1;

=head1 NAME

CBQZ::Db::Base::Result::User

=head1 SYNOPSIS

    use CBQZ::Model::User;
    my $user = CBQZ::Model::User->new->load(42);

    $user->obj->update({ passwd => 'New Password' });

=head1 DESCRIPTION

Role for inclusion into L<CBQZ::Db::Result::User>, which is
auto-generated. This module exists so that the core L<DBIx::Class> schema
modules can be auto-generated with the schema generator.

=head1 AROUND

=head2 passwd

When setting the column "passwd" for a challenge, the text of "passwd" will
be hashed using L<Digest::SHA>'s C<sha256_hex> method.
