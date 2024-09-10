use Config::App;
use Test::Most;
use Test::Moose;
use Test::MockModule;
use Try::Tiny;
use CBQZ::Error;
use CBQZ::Util::Log;
use exact -notry;

use constant PACKAGE => 'CBQZ';

Config::App->new->put( 'logging', 'filter', 'all' );
exit main();

sub main {
    BEGIN { use_ok(PACKAGE) }
    require_ok(PACKAGE);

    my $obj = PACKAGE->new;
    isa_ok( $obj, PACKAGE );

    my @loggers = qw(
        debug info notice warning warn error err critical crit alert emergency emerg
    );
    can_ok( PACKAGE, $_ ) for ( qw( able clean_error yaml dp dsn ), @loggers );

    params_check($obj);
    able($obj);
    yaml($obj);
    clean_error($obj);
    log_helpers( $obj, @loggers );

    done_testing();
    return 0;
};

sub params_check ($obj) {
    throws_ok(
        sub { $obj->params_check( [ 'an error message', sub { 1 == 1 } ] ) },
        'E',
        'single params_check error',
    );

    lives_ok(
        sub { $obj->params_check( [ 'an error message', sub { 1 == 0 } ] ) },
        'single params_check pass',
    );

    return;
}

sub able ($obj) {
    ok( $obj->able( $obj, 'able' ), '$obj->able' );
    is( $obj->able( $obj, 'not_implemented' ), undef, '$obj->able not implemented' );
    return;
}

sub yaml ($obj) {
    can_ok( $obj->yaml, $_ ) for ( qw( load dump load_file dump_file ) );
    is( $obj->yaml->dump({ answer => 42 }), "---\nanswer: 42\n", '$obj->yaml->dump' );
    is_deeply( $obj->yaml->load("---\nanswer: 42\n"), { answer => 42 }, '$obj->yaml->load' );
    return;
}

sub clean_error ($obj) {
    my $count = 0;
    is( $obj->clean_error( $_->[0] ), $_->[1], '$obj->error test ' . ++$count ) for (
        [ 'Error occured at SomeClass::method line 42', 'Error occured' ],
        [ 'Error occured', 'Error occured' ],
        [ 'Error occured at start at Location line 42', 'Error occured at start' ],
    );

    my $e;
    try {
        E->throw('Error message in an E object');
    }
    catch {
        $e = $_ || $@;
    };

    is( $obj->clean_error($e), 'Error message in an E object', '$obj->clean_error( E->throw )' );

    return;
}

sub log_helpers ( $obj, @loggers ) {
    my $mock_log = Test::MockModule->new('Log::Dispatch');
    $mock_log->mock( $_ => sub { shift; return @_ } ) for (@loggers);

    my $mock = Test::MockModule->new( ref $obj );
    $mock->mock( log => sub { CBQZ::Util::Log->new } );

    for my $level (@loggers) {
        my @rv;
        lives_ok( sub { @rv = $obj->$level('message') }, '$obj->' . $level . ' call' );
        is( $rv[0], 'message', '$obj->' . $level . ' value' );
    }

    return;
}
