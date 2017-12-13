use Mojo::Base -strict;
use Config::App;
use Test::Most;
use Test::Mojo;
use exact;

my $t = Test::Mojo->new('CBQZ::Control');
$t->ua->max_redirects(10);

$t->get_ok('/')->status_is(200)
    ->element_exists('div#header_login form input#login_form_submit')
    ->element_exists('div#content form#create_form select option');

$t->post_ok( '/login' => form => {
    name   => 'admin',
    passwd => 'incorrect_password',
} )->status_is(200)
    ->element_exists('div#header_login form input#login_form_submit')
    ->element_exists('div#message')
    ->text_like( 'div#message' => qr/Login failed/ );

done_testing();
