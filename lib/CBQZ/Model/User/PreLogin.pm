package CBQZ::Model::User::PreLogin;

use Moose::Role;
use exact;
use Digest::SHA 'sha256_hex';
use CBQZ::Model::Email;

sub create ( $self, $params ) {
    $self->params_check(
        [ '"username" not defined in input', sub { not defined $params->{username} }                      ],
        [ '"username" length < 2 in input',  sub { length $params->{username} < 2 }                       ],
        [ '"passwd" complexity not met', sub { not $self->password_quality( $params->{passwd} ) } ],
    );

    $self->params_check(
        [ '"username" cannot begin with _', sub { index( $params->{username}, '_' ) == 0 } ],
    ) unless ( delete $params->{_} );

    my $program_id = delete $params->{program};
    try {
        my $passwd = delete $params->{passwd};

        $self->obj( $self->rs->create($params)->get_from_storage );
        $self->obj->update({ passwd => $passwd });

        $self->add_program($program_id) if ($program_id);
    }
    catch {
        E->throw('Failed to create user that already exists')
            if ( index( ( $_ || $@ ), 'Duplicate entry' ) > -1 );
        E->throw( $_ || $@ );
    };

    $self->event('create_user');

    # if (
    #     my @emails = map { $_->[0] } @{ $self->dq->sql(q{
    #         (
    #             SELECT DISTINCT email
    #             FROM user
    #             JOIN role USING (user_id)
    #             WHERE role.type = 'administrator'
    #         )
    #         UNION
    #         (
    #             SELECT DISTINCT email
    #             FROM user
    #             JOIN role USING (user_id)
    #             WHERE role.type = 'director' AND role.program_id = ?
    #         )
    #     })->run( $program_id || 0 )->all }
    # ) {
    #     CBQZ::Model::Email->new( type => 'new_user_registration' )->send({
    #         to   => \@emails,
    #         data => {
    #             username => $self->obj->username,
    #             realname => $self->obj->realname,
    #             email    => $self->obj->email,
    #         },
    #     });
    # }

    $self->add_role( 'user', $program_id );

    # if there are no user with the "administrator" role, add the "administrator" roll to this new user
    $self->add_role( 'administrator', $program_id ) unless (
        $self->rs->search(
            {
                'me.active'  => 1,
                'roles.type' => 'administrator',
            },
            {
                'join' => 'roles',
            },
        )->count
    );

    return $self;
}

sub login ( $self, $params ) {
    $self->params_check(
        [ 'Valid "username" not in input', sub { not $params->{username} } ],
        [ 'Valid "passwd" not in input', sub { not $params->{passwd} } ],
    );

    $params->{active} = 1;
    $params->{passwd} = sha256_hex( $params->{passwd} );

    my $user = $self->rs->search($params)->first;

    unless ($user) {
        $self->event( 'login_fail', $user->id )
            if ( $user = $self->rs->search({ username => $params->{username} })->first );

        $self->info( 'Login failure (in model) for: ' . $params->{username} );
        E->throw('Invalid login');
    }

    $self->obj($user);
    $self->event('login');

    $user->update({ last_login => \q{ NOW() } });

    return $self;
}

1;
