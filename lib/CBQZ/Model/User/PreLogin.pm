package CBQZ::Model::User::PreLogin;

use Moose::Role;
use Try::Tiny;

sub create {
    my ( $self, $params ) = @_;

    $self->params_check(
        [ '"name" not defined in input',   sub { not defined $params->{name} }   ],
        [ '"name" length < 6 in input',    sub { length $params->{name} < 6 }    ],
        [ '"passwd" not defined in input', sub { not defined $params->{passwd} } ],
        [ '"passwd" length < 8 in input',  sub { length $params->{passwd} < 8 }  ],
        [ '"passwd" complexity not met',   sub {
            not $self->password_quality( $params->{passwd} )
        } ],
    );

    $self->params_check(
        [ '"name" cannot begin with _', sub { index( $params->{name}, '_' ) == 0 } ],
    ) unless ( delete $params->{_} );

    try {
        $self->obj( $self->rs->create($params)->get_from_storage );
    }
    catch {
        E->throw('Failed to create user that already exists')
            if ( index( $_, 'Duplicate entry' ) > -1 );
        E->throw($_);
    };

    return $self;
}

sub login {
    my ( $self, $params ) = @_;

    $self->params_check(
        [ 'Valid "name" not in input',   sub { not $params->{name} }   ],
        [ 'Valid "passwd" not in input', sub { not $params->{passwd} } ],
    );

    $params->{active} = 1;

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
