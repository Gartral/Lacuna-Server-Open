package Lacuna::DB::Building::Espionage;

use Moose;
extends 'Lacuna::DB::Building';

use constant controller_class => 'Lacuna::Building::Espionage';

use constant max_instances_per_planet => 1;

use constant building_prereq => {'Lacuna::DB::Building::Intelligence'=>1};

use constant image => 'espionage';

use constant name => 'Espionage Ministry';

use constant food_to_build => 70;

use constant energy_to_build => 70;

use constant ore_to_build => 70;

use constant water_to_build => 70;

use constant waste_to_build => 70;

use constant time_to_build => 600;

use constant food_consumption => 25;

use constant energy_consumption => 50;

use constant ore_consumption => 10;

use constant water_consumption => 25;

use constant waste_production => 5;


no Moose;
__PACKAGE__->meta->make_immutable;
