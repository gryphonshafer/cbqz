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

    can_ok( PACKAGE, $_ ) for ( qw( role_names roles_count has_role add_role remove_role ) );

    done_testing();
    return 0;
};
