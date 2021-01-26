use Config::App;
use Test::Most;
use exact;

use constant PACKAGE => 'CBQZ::Util::Format';

exit main();

{
    package _TestThis;
    use CBQZ::Util::Format 'log_date';
}

sub main {
    BEGIN { use_ok(PACKAGE) }
    require_ok(PACKAGE);

    my $date;
    lives_ok( sub { $date = _TestThis::log_date(1513110477) }, 'log_date() call' );
    is( $date, 'Dec 12 12:27:57 2017', 'log_date() data' );

    done_testing();
    return 0;
};
