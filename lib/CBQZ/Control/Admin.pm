package CBQZ::Control::Admin;

use Mojo::Base 'Mojolicious::Controller';
use exact;

sub index ($self) {
    my $roles = $self->stash('user')->db->enum( 'role', 'type' );

    $self->stash(
        roles    => $roles,
        programs => [
            map {
                my $program = $_;

                +{
                    %{ $program->data },
                    users => [
                        sort { $a->{name} cmp $b->{name} }
                        map {
                            my $user       = $_;
                            my @user_roles = map {
                                +{ $_->get_inflated_columns }
                            } $user->roles( undef, $program->obj->id );

                            +{
                                %{ $user->data },
                                roles => [
                                    map {
                                        my $role = $_;

                                        +{
                                            name   => $role,
                                            active => ( grep { $role eq $_->{type} } @user_roles ) ? 1 : 0,
                                        };
                                    } @$roles
                                ],
                            };
                        } $_->users
                    ],
                };
            }
            sort { $a->obj->name cmp $b->obj->name }
            (
                ( $self->stash('user')->has_role('Administrator') )
                    ? CBQZ::Model::Program->new->every
                    : grep {
                        $self->stash('user')->has_role( 'Director', $_->obj->id )
                    } @{ $self->stash('user')->programs }
            )
        ],
    );
}

1;
