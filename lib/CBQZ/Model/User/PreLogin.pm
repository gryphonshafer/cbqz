package CBQZ::Model::User::PreLogin;

use Moose::Role;
use exact;
use Try::Tiny;
use Digest::SHA 'sha256_hex';

sub create ( $self, $params ) {
    $self->params_check(
        [ '"name" not defined in input', sub { not defined $params->{name} }                      ],
        [ '"name" length < 2 in input',  sub { length $params->{name} < 2 }                       ],
        [ '"passwd" complexity not met', sub { not $self->password_quality( $params->{passwd} ) } ],
    );

    $self->params_check(
        [ '"name" cannot begin with _', sub { index( $params->{name}, '_' ) == 0 } ],
    ) unless ( delete $params->{_} );

    try {
        my $program_id = delete $params->{program};
        my $passwd     = delete $params->{passwd};

        $self->obj( $self->rs->create($params)->get_from_storage );
        $self->obj->update({ passwd => $passwd });

        $self->add_program($program_id) if ($program_id);
    }
    catch {
        E->throw('Failed to create user that already exists')
            if ( index( $_, 'Duplicate entry' ) > -1 );
        E->throw($_);
    };

    $self->event('create_user');

    # if there are no user with the "admin" role, add the admin roll to this new user
    $self->add_role('admin') unless (
        $self->rs->search(
            {
                'me.active'  => 1,
                'roles.type' => 'admin',
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
        [ 'Valid "name" not in input',   sub { not $params->{name} }   ],
        [ 'Valid "passwd" not in input', sub { not $params->{passwd} } ],
    );

    $params->{active} = 1;
    $params->{passwd} = sha256_hex( $params->{passwd} );

    my $user = $self->rs->search($params)->first;

    unless ($user) {
        $self->event( 'login_fail', $user->id )
            if ( $user = $self->rs->search({ name => $params->{name} })->first );

        $self->info( 'Login failure (in model) for: ' . $params->{name} );
        E->throw('Invalid login');
    }

    $self->obj($user);
    $self->event('login');

    $user->update({ last_login => \q{ NOW() } });

    return $self;
}

1;
