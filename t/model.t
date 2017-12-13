use exact;
use Config::App;
use Test::Most;
use Test::Moose;

use constant PACKAGE => 'CBQZ::Model';

exit main();

sub main {
    BEGIN { use_ok(PACKAGE) }
    require_ok(PACKAGE);

    my $obj = PACKAGE->new;
    isa_ok( $obj, PACKAGE );

    can_ok( PACKAGE, $_ ) for ( qw( load rs create data model every every_data ) );
    has_attribute_ok( PACKAGE, 'obj' );

    lives_ok( sub { $obj->schema_name('User') }, '$obj->schema_name' );
    throws_ok( sub { $obj->load(0) }, qr/Failed to load object from database given PK/, '$obj->load' );
    lives_ok( sub { $obj->rs }, '$obj->rs' );
    lives_ok( sub { $obj->rs('User') }, '$obj->rs($schema_name)' );
    lives_ok( sub { my $rs = $obj->rs( 'User', { active => 1 } ) }, '$obj->rs( $schema_name, @params )' );

    done_testing();
    return 0;
};
