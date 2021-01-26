use Config::App;
use Test::Most;
use exact;

use constant PACKAGE => 'CBQZ::Util::File';

exit main();

{
    package _TestThis;
    use CBQZ::Util::File qw( filename slurp spurt );
}

sub main {
    BEGIN { use_ok(PACKAGE) }
    require_ok(PACKAGE);

    my $filename;
    lives_ok( sub { $filename = _TestThis::filename( 'Things:', 'And+', 'Stuff;' ) }, 'filename() call' );
    is( $filename, 'things/and/stuff', 'filename() data' );

    my $file = 't_util_file.t_' . time . rand;
    lives_ok( sub { _TestThis::spurt( $file, "test\nfile\ncontent\n" ) }, 'spurt() call' );

    my $content;
    lives_ok( sub { $content = _TestThis::slurp($file) }, 'slurp() call' );
    is( $content, "test\nfile\ncontent\n", 'file content' );

    unlink $file;

    done_testing();
    return 0;
};
