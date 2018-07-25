package CBQZ::Model::Program;

use Moose;
use MooseX::ClassAttribute;
use exact;
use CBQZ::Model::User;
use CBQZ::Util::File 'slurp';

extends 'CBQZ::Model';

class_has 'schema_name' => ( isa => 'Str',     is => 'ro', default => 'Program' );
class_has 'defaults'    => ( isa => 'HashRef', is => 'ro', default => sub {
    +{
        target_questions => 40,
        timer_default    => 30,
        timeout          => 60,
        timer_values     => [ 5, 30, 60 ],
        readiness        => 20,
        as_default       => 'Standard',
        question_types   => [
            [ ['INT'],                     [ 8, 12 ], 'INT' ],
            [ ['MA'],                      [ 2,  7 ], 'MA'  ],
            [ [ qw( CR CVR MACR MACVR ) ], [ 3,  5 ], 'Ref' ],
            [ [ qw( Q Q2V ) ],             [ 1,  2 ], 'Q'   ],
            [ [ qw( FT FTN FTV F2V ) ],    [ 2,  3 ], 'F'   ],
            [ ['SIT'],                     [ 0,  4 ], 'SIT' ],
        ],
        score_types      => [
            '3-Team 20-Question',
            '2-Team 15-Question Tie-Breaker',
            '2-Team 20-Question',
            '2-Team Overtime',
            '3-Team Overtime',
        ],
    }
} );

sub default ( $self, $name ) {
    return ( $name eq 'result_operation' )
        ? slurp( $self->config->get( qw( config_app root_dir ) ) . '/static/js/pages/result_operation.js' )
        : ( exists $self->defaults->{$name} ) ? $self->defaults->{$name} : undef;
}

sub string_defaults ($self) {
    return {
        question_types   => $self->question_types_as_text( $self->default('question_types') ),
        timer_values     => join( ', ', @{ $self->default('timer_values') } ),
        score_types      => join( "\n", @{ $self->default('score_types') } ),
        result_operation => $self->default('result_operation'),
        map { $_ => $self->default($_) } qw( target_questions timer_default timeout readiness as_default ),
    };
}

sub rs ( $self, @params ) {
    my $programs = $self->SUPER::rs(@params);
    return ( $programs->count ) ? $programs : $self->create_default;
}

sub create_default ($self) {
    my $rs = $self->db->resultset( $self->schema_name )->result_source->resultset;

    $rs->set_cache([ $rs->create({
        name             => 'Default Quiz Program',
        question_types   => $self->json->encode( $self->default('question_types') ),
        result_operation => $self->default('result_operation'),
        timer_values     => $self->json->encode( $self->default('timer_values') ),
        as_default       => $self->default('as_default'),
        score_types      => $self->json->encode( $self->default('score_types') ),
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

sub admin_data ( $self, $user, $roles ) {
    return [
        map {
            my $program = $_;

            +{
                %{ $program->data },
                question_types => $program->question_types_as_text,
                timer_values   => join( ', ', @{ $self->json->decode( $program->obj->timer_values ) } ),
                score_types    => join( "\n", @{ $self->json->decode( $program->obj->score_types ) } ),
                users          => [
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
            ( $user->has_role('administrator') )
                ? CBQZ::Model::Program->new->every
                : grep {
                    $user->has_role( 'director', $_->obj->id )
                } @{ $user->programs }
        )
    ];
}

sub question_types_parse ( $self, $text ) {
    return [
        map {
            my ( $label, $min, $max, @types ) = split(/\W+/);
            [ \@types, [ $min, $max ], $label ];
        }
        grep { /^\W*\w+\W+\w+\W+\w+\W+\w+/ }
        split( /\r?\n/, $text // '' )
    ];
}

sub question_types_as_text ( $self, $question_types = undef ) {
    $question_types //= $self->obj->question_types;
    $question_types = $self->json->decode($question_types) unless ( ref $question_types );

    return join( "\n",
        map {
            $_->[2] . ': ' . $_->[1][0] . '-' . $_->[1][1] . ' (' . join( ' ', @{ $_->[0] } ) . ')'
        } @$question_types
    );
}

__PACKAGE__->meta->make_immutable;

1;
