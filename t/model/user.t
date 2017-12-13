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

    can_ok( PACKAGE, $_ ) for ( qw( password_quality change_name change_passwd event question_sets ) );

    password_quality($obj);

    done_testing();
    return 0;
};

sub password_quality ($obj) {
    is( !! $obj->password_quality('bad'), '', 'password_quality bad' );
    is( !! $obj->password_quality('a_gooder_password_ish'), 1, 'password_quality good' );
}
