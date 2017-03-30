use exact;
use Config::App;
use Test::Most;

use constant PACKAGE => 'CBQZ::Util::Format';

exit main();

{
    package _TestThis;
    use CBQZ::Util::Format qw(
        log_date
    );
}

sub main {
    BEGIN { use_ok(PACKAGE) }
    require_ok(PACKAGE);

    done_testing();
    return 0;
};
