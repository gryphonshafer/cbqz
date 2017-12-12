use exact;
use Config::App;
use Test::Most;

use constant PACKAGE => 'CBQZ::Util::Log';

exit main();

sub main {
    BEGIN { use_ok(PACKAGE) }
    require_ok(PACKAGE);

    my $log;
    lives_ok( sub { $log = PACKAGE->new }, 'new()' );
    is( ref($log), 'Log::Dispatch', 'is a Log::Dispatch' );

    done_testing();
    return 0;
};
