package Lacuna::DB::Building::Waste::Recycling;

use Moose;
extends 'Lacuna::DB::Building::Waste';

use constant controller_class => 'Lacuna::Building::WasteRecycling';

use constant image => 'wasterecycling';

use constant university_prereq => 3;

use constant name => 'Waste Recycling Center';

use constant food_to_build => 100;

use constant energy_to_build => 100;

use constant ore_to_build => 100;

use constant water_to_build => 100;

use constant waste_to_build => 20;

use constant time_to_build => 950;

use constant food_consumption => 5;

use constant energy_consumption => 10;

use constant ore_consumption => 5;

use constant water_consumption => 5;

use constant waste_consumption => 5;



no Moose;
__PACKAGE__->meta->make_immutable;
