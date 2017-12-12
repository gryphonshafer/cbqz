use exact;
use Config::App;
use Test::Most;
use Test::Moose;
use Try::Tiny;

use constant PACKAGE => 'CBQZ::Error';

exit main();

sub main {
    BEGIN { use_ok(PACKAGE) }
    require_ok(PACKAGE);

    my $e;
    lives_ok(
        sub {
            try {
                E->throw('Error message');
            }
            catch {
                $e = $_;
            };
        },
        q{E->throw('Error message')},
    );
    is( ref($e), 'E', 'Thrown error is of class E' );
    is( $e->message, 'Error message', 'Thrown error message is correct' );

    lives_ok(
        sub {
            try {
                E::Db->throw(
                    message => 'Specific database error with SQL',
                    sql     => 'SELECT a_column FROM some_table',
                );
            }
            catch {
                $e = $_;
            };
        },
        q{E::Db->throw(...)},
    );
    is( ref($e), 'E::Db', 'Thrown error is of class E::Db' );
    is( $e->message, 'Specific database error with SQL', 'Error db message' );
    is( $e->sql, 'SELECT a_column FROM some_table', 'Error sql message' );

    done_testing();
    return 0;
};
