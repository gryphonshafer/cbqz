use Config::App;
use Test::Most;
use Test::Moose;
use exact;

use constant PACKAGE => 'CBQZ::Model::MaterialSet';

exit main();

sub main {
    BEGIN { use_ok(PACKAGE) }
    require_ok(PACKAGE);

    my $obj = PACKAGE->new;
    isa_ok( $obj, PACKAGE );

    can_ok( PACKAGE, 'get_material' );

    my $material;
    throws_ok( sub { $obj->get_material }, qr/Can't call method/, '$obj->get_material throws pre-load' );

    done_testing();
    return 0;
};
