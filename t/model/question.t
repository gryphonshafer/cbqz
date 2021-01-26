use Config::App;
use Test::Most;
use Test::Moose;
use exact;

use constant PACKAGE => 'CBQZ::Model::Question';

exit main();

sub main {
    BEGIN { use_ok(PACKAGE) }
    require_ok(PACKAGE);

    my $obj = PACKAGE->new;
    isa_ok( $obj, PACKAGE );

    can_ok( PACKAGE, 'is_owned_by' );

    done_testing();
    return 0;
};
