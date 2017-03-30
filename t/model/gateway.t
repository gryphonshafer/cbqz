use exact;
use Config::App;
use Test::Most;
use Test::Moose;

use constant PACKAGE => 'CBQZ::Model::Gateway';

Config::App->new->put( 'logging', 'filter', 'all' );
exit main();

sub main {
    BEGIN { use_ok(PACKAGE) }
    require_ok(PACKAGE);

    my $obj = PACKAGE->new;
    isa_ok( $obj, PACKAGE );

    done_testing();
    return 0;
};
