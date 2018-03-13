package CBQZ::Model::Program;

use Moose;
use MooseX::ClassAttribute;
use exact;
use CBQZ::Model::User;

extends 'CBQZ::Model';

class_has 'schema_name' => ( isa => 'Str', is => 'ro', default => 'Program' );

sub rs ($self) {
    my $programs = $self->SUPER::rs;
    return ( $programs->count ) ? $programs : $self->create_default;
}

sub create_default ($self) {
    my $rs = $self->db->resultset( $self->schema_name )->result_source->resultset;

    $rs->set_cache([ $rs->create({
        name           => 'Default Quiz Program',
        question_types => $self->json->encode(
            [
                [ ['INT'],                     [ 8, 12 ], 'INT' ],
                [ [ qw( MA MACR MACVR ) ],     [ 2,  7 ], 'MA'  ],
                [ [ qw( CR CVR MACR MACVR ) ], [ 3,  5 ], 'Ref' ],
                [ [ qw( Q Q2V ) ],             [ 1,  2 ], 'Q'   ],
                [ [ qw( FT FTN FTV F2V ) ],    [ 2,  3 ], 'F'   ],
                [ ['SIT'],                     [ 0,  4 ], 'SIT' ],
            ],
        ),
        target_questions => 40,
        result_operation => q/
            if ( result == "correct" ) {
                as     = "Standard";
                number = parseInt(number) + 1;
            }
            else if ( result == "error" ) {
                if ( as == "Standard" ) {
                    as = "Toss-Up";
                }
                else if ( as == "Toss-Up" ) {
                    as = "Bonus";
                }
                else if ( as == "Bonus" ) {
                    as = "Standard";
                }

                if ( parseInt(number) < 16 ) {
                    number = parseInt(number) + 1;
                }
                else if ( number == parseInt(number) ) {
                    number = parseInt(number) + "A";
                }
                else if ( number == parseInt(number) + "A" ) {
                    number = parseInt(number) + "B";
                }
                else if ( number == parseInt(number) + "B" ) {
                    number = parseInt(number) + 1;
                }
            }
            else if ( result == "no_jump" ) {
                as     = "Standard";
                number = parseInt(number) + 1;
            }
        /,
        timer_values  => $self->json->encode([ 5, 30, 60 ]),
        timer_default => 30,
        as_default    => 'Standard',
    })->get_from_storage ]);

    return $rs;
}

sub types_list ($self) {
    my %seen;

    return [
        grep { defined }
        map { ( $seen{$_}++ ) ? undef : $_ }
        map { @{ $_->[0] } } @{
            $self->json->decode(
                scalar(
                    $self->dq->sql(q{
                        SELECT question_types
                        FROM program
                        WHERE program_id = ?
                    })->run( $self->obj->id )->value
                )
            )
        }
    ];
}

sub timer_values ($self) {
    return $self->json->decode(
        scalar(
            $self->dq->sql(q{
                SELECT timer_values
                FROM program
                WHERE program_id = ?
            })->run( $self->obj->id )->value
        )
    );
}

sub users ($self) {
    my $users = CBQZ::Model::User->new->model( map { $_->user } $self->obj->user_programs );
    return (wantarray) ? @$users : $users;
}

sub admin_roles_data ( $self, $user, $roles ) {
    return [
        map {
            my $program = $_;

            +{
                %{ $program->data },
                users => [
                    sort { lc $a->{username} cmp lc $b->{username} }
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
            ( $user->has_role('Administrator') )
                ? CBQZ::Model::Program->new->every
                : grep {
                    $user->has_role( 'Director', $_->obj->id )
                } @{ $user->programs }
        )
    ];
}

__PACKAGE__->meta->make_immutable;

1;
