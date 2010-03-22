use lib '../lib';
use Test::More tests => 4;
use Test::Deep;
use Data::Dumper;
use 5.010;

use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $db = $tester->db;
my $empire = $tester->empire;
my $session_id = $tester->session->id;

my $command = $empire->home_planet->command;
$command->level(5);
$command->put;

my $result;

$result = $tester->post('park', 'build', [$session_id, $empire->home_planet_id, 3, 3]);

my $building = $db->domain('Lacuna::DB::Building::Park')->find($result->{result}{building}{id});
$building->finish_upgrade;

$result = $tester->post('park', 'throw_a_party', [$session_id, $building->id]);

is($result->{error}{code}, 1011, "can't throw a party without food");

my $body = $building->body;
$body->algae_stored(20000);
$body->put;

$result = $tester->post('park', 'throw_a_party', [$session_id, $building->id]);
cmp_ok($result->{result}{seconds_remaining}, '>', 0, "timer is started");
$result = $tester->post('park', 'view', [$session_id, $building->id]);
cmp_ok($result->{result}{status}{planets}[0]{food_stored}, '<', 20_000, "food gets spent");
my $happy = $result->{result}{status}{planets}[0]{happiness};

$building = $db->domain('Lacuna::DB::Building::Park')->find($result->{result}{building}{id});
$building->end_the_party;
cmp_ok($result->{result}{status}{planets}[0]{happiness}, '<', $building->body->happiness, "happiness is increased");



END {
    $tester->cleanup;
}
