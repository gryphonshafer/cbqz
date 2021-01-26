use Config::App;
use Test::Most;
use exact;

use constant {
    PACKAGE    => 'CBQZ::Db',
    SUBPACKAGE => 'CBQZ::Db::Schema',
};

exit main();

sub main {
    BEGIN {
        use_ok(PACKAGE);
        use_ok(SUBPACKAGE);
    }
    require_ok(PACKAGE);
    require_ok(SUBPACKAGE);

    my $db;
    lives_ok( sub { $db = SUBPACKAGE->connect }, 'CBQZ::Db::Schema->connect' );
    lives_ok( sub { $db = SUBPACKAGE->connect }, 'CBQZ::Db::Schema->connect 2' );
    is( ref($db), 'CBQZ::Db::Schema', 'connect returns a CBQZ::Db::Schema object' );

    done_testing();
    return 0;
};
