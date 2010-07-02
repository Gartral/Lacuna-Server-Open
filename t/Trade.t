use lib '../lib';
use Test::More tests => 2;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;

use TestHelper;
my $tester = TestHelper->new->generate_test_empire->build_infrastructure;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;

my $result;


$result = $tester->post('spaceport', 'build', [$session_id, $home->id, 0, 1]);
my $spaceport = $tester->get_building($result->{result}{building}{id});
$spaceport->finish_upgrade;

$result = $tester->post('shipyard', 'build', [$session_id, $home->id, 0, 2]);
my $shipyard = $tester->get_building($result->{result}{building}{id});
$shipyard->finish_upgrade;

$result = $tester->post('trade', 'build', [$session_id, $home->id, 0, 3]);
ok($result->{result}{building}{id}, "built a trade ministry");
my $trade = $tester->get_building($result->{result}{building}{id});
$trade->finish_upgrade;

$result = $tester->post('trade', 'view_my_trades', [$session_id, $trade->id]);
ok(exists $result->{result}, 'can call view_my_trades when there are no trades');

END {
    $tester->cleanup;
}