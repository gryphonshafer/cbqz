use exact;
use Config::App;
use Test::Most;
use Test::Moose;

use constant PACKAGE => 'CBQZ::Model::Program';

exit main();

sub main {
    BEGIN { use_ok(PACKAGE) }
    require_ok(PACKAGE);

    my $obj = PACKAGE->new;
    isa_ok( $obj, PACKAGE );

    can_ok( PACKAGE, $_ ) for ( qw( rs create_default types_list timer_values ) );

    my $rs;
    lives_ok( sub { $rs = $obj->rs }, '$obj->rs' );
    lives_ok( sub { $obj->load( $rs->first->id ) }, '$obj->load' );

    my $types_list;
    lives_ok( sub { $types_list = $obj->types_list }, '$obj->types_list' );
    ok( ref($types_list) eq 'ARRAY' && @$types_list > 0, 'types list looks OK' );

    my $timer_values;
    lives_ok( sub { $timer_values = $obj->timer_values }, '$obj->timer_values' );
    ok( ref($timer_values) eq 'ARRAY' && @$timer_values > 0, 'timer values look OK' );

    done_testing();
    return 0;
};
