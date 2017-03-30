use exact;
use Config::App;
use Test::Most;
use Test::Moose;

use constant PACKAGE => 'CBQZ';

Config::App->new->put( 'logging', 'filter', 'all' );
exit main();

sub main {
    BEGIN { use_ok(PACKAGE) }
    require_ok(PACKAGE);

    my $obj = PACKAGE->new;
    isa_ok( $obj, PACKAGE );

    can_ok( PACKAGE, $_ ) for ( qw(
        params_check able clean_error
        debug info notice warning warn error err critical crit alert emergency emerg
    ) );

    params_check($obj);
    clean_error($obj);

    done_testing();
    return 0;
};

sub params_check {
    my ($obj) = @_;

    throws_ok(
        sub { $obj->params_check( [ 'pass', sub { 0 } ] ) },
        qr/^$/,
        q{$obj->params_check( [ 'test', sub { 0 } ] )},
    );

    throws_ok(
        sub { $obj->params_check( [ 'fail', sub { 1 } ] ) },
        qr|^fail|,
        q{$obj->params_check( [ 'fail', sub { 1 } ] )},
    );

    return;
}

sub clean_error {
    my ($obj) = @_;

    my $count = 0;
    is( $obj->clean_error( $_->[0] ), $_->[1], '$obj->error test ' . ++$count ) for (
        [ 'Error occured at SomeClass::method line 42', 'Error occured' ],
        [ 'Error occured', 'Error occured' ],
        [ 'Error occured at start at Location line 42', 'Error occured at start' ],
    );

    return;
}
