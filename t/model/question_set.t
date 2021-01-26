use Config::App;
use Test::Most;
use Test::Moose;
use exact;

use constant PACKAGE => 'CBQZ::Model::QuestionSet';

exit main();

sub main {
    BEGIN { use_ok(PACKAGE) }
    require_ok(PACKAGE);

    my $obj = PACKAGE->new;
    isa_ok( $obj, PACKAGE );

    can_ok( PACKAGE, $_ ) for ( qw( create get_questions generate_statistics data is_owned_by ) );

    my $sets = $obj->rs->search;
    if ( $sets->count ) {
        my $set = $sets->next;
        $obj->obj($set);

        my $rv;
        lives_ok( sub { $rv = $obj->get_questions }, '$obj->get_questions' );
        lives_ok( sub { $rv = $obj->generate_statistics }, '$obj->generate_statistics' );
        lives_ok( sub { $rv = $obj->data }, '$obj->data' );
    }

    done_testing();
    return 0;
};
