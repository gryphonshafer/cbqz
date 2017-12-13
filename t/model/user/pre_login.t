use exact;
use Config::App;
use Test::Most;
use Test::Moose;
use CBQZ::Model;

use constant PACKAGE => 'CBQZ::Model::User';

exit main();

sub main {
    BEGIN { use_ok(PACKAGE) }
    require_ok(PACKAGE);

    my $obj = PACKAGE->new;
    isa_ok( $obj, PACKAGE );

    can_ok( PACKAGE, $_ ) for ( qw( create login ) );

    done_testing();
    return 0;
};
