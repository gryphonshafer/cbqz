package CBQZ::Control::Admin;

use Mojo::Base 'Mojolicious::Controller';
use exact;
use CBQZ::Model::Program;
use CBQZ::Model::User;
use CBQZ::Model::Meet;

sub index ($self) {
    my $roles = [ grep { $_ ne 'administrator' } @{ $self->stash('user')->db->enum( 'role', 'type' ) } ];

    $self->stash(
        roles    => $roles,
        programs => CBQZ::Model::Program->new->admin_data( $self->stash('user'), $roles ),
    );
}

sub save_roles_changes ($self) {
    my $roles    = [ grep { $_ ne 'administrator' } @{ $self->stash('user')->db->enum( 'role', 'type' ) } ];
    my $programs = CBQZ::Model::Program->new->admin_data( $self->stash('user'), $roles );

    my $checks;
    $checks->{ $_->[0] }{ $_->[1] }{ $_->[2] } = $_->[3]
        for ( map { [ split(/\|/) ] } keys %{ $self->params } );

    my $changes = 0;
    for my $program (@$programs) {
        for my $user ( @{ $program->{users} } ) {
            my $user_model;

            for my $role ( @{ $user->{roles} } ) {
                my $check = undef;
                try { $check = $checks->{ $program->{program_id} }{ $user->{user_id} }{ $role->{name} } };

                if ( defined $check and $check == 0 ) {
                    $user_model ||= CBQZ::Model::User->new->load( $user->{user_id} );
                    $changes++;
                    $user_model->add_role( $role->{name}, $program->{program_id} );
                }
                elsif ( not defined $check and $role->{active} ) {
                    $user_model ||= CBQZ::Model::User->new->load( $user->{user_id} );
                    $changes++;
                    $user_model->remove_role( $role->{name}, $program->{program_id} );
                }
            }
        }
    }

    $self->stash('user')->event('save_roles_changes');

    $self->flash( message => {
        type => 'success',
        text => ($changes) ? "$changes user roles changes saved." : 'No user roles were changed.',
    } );

    return $self->redirect_to('/admin');
}

sub config ($self) {
    my $roles   = [ grep { $_ ne 'administrator' } @{ $self->stash('user')->db->enum( 'role', 'type' ) } ];
    my $program = CBQZ::Model::Program->new;

    $self->stash(
        programs => $program->admin_data( $self->stash('user'), $roles ),
        defaults => $program->json->encode( $program->string_defaults ),
    );
}

sub save_program_config ($self) {
    my $roles      = [ grep { $_ ne 'administrator' } @{ $self->stash('user')->db->enum( 'role', 'type' ) } ];
    my $programs   = CBQZ::Model::Program->new->admin_data( $self->stash('user'), $roles );
    my $program_id = $self->req->param('program_id');

    unless ( grep { $program_id == $_->{program_id} } @$programs ) {
        $self->flash( message => 'Authorization error encountered. Unable to save program changes.' );
    }
    else {
        my $program = CBQZ::Model::Program->new->load($program_id);
        my $params  = $self->params;

        $params->{question_types} = $program->json->encode(
            $program->question_types_parse( $params->{question_types} )
        );

        $params->{timer_values} = $program->json->encode( [
            map { 0 + $_ } grep { /^\d+$/ } split( /\D+/, $params->{timer_values} )
        ] );

        $params->{score_types} = $program->json->encode( [
            map { s/^\s+|\s+$//g; $_ } grep { /\S/ } split( /\r?\n/, $params->{score_types} )
        ] );

        delete $params->{program_id};
        $program->obj->update($params);

        $self->stash('user')->event('save_program_config');

        $self->flash( message => {
            type => 'success',
            text => 'Program configuration changes saved.',
        } );
    }

    return $self->redirect_to('/admin/config');
}

sub build_draw ($self) {
    my $settings = { map { $_ => $self->param($_) } ( qw( rooms quizzes teams norandom ) ) };

    if ( $settings->{rooms} and $settings->{quizzes} and $settings->{teams} ) {
        try {
            $settings->{teams} = [ grep { length } split( /\s*\r?\n\s*/, $settings->{teams} ) ];
            my ( $meet, $team_stats, $quiz_stats ) = CBQZ::Model::Meet->build_draw($settings);
            $self->stash(
                meet       => $meet,
                team_stats => $team_stats,
                quiz_stats => $quiz_stats,
            );
        }
        catch {
            $self->notice( 'Build draw error: ' . $self->cbqz->clean_error( $_ || $@ ) );
            $self->stash( message => $self->cbqz->clean_error( $_ || $@ ) );
        };
    }
}

1;
