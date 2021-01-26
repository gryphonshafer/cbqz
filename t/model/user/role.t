use Config::App;
use Test::Most;
use Test::Moose;
use CBQZ::Model;
use exact;

use constant PACKAGE => 'CBQZ::Model::User';

exit main();

sub main {
    BEGIN { use_ok(PACKAGE) }
    require_ok(PACKAGE);

    my $obj = PACKAGE->new;
    isa_ok( $obj, PACKAGE );

    can_ok( PACKAGE, $_ ) for ( qw( roles has_role has_any_role_in_program add_role remove_role ) );

    done_testing();
    return 0;
};
