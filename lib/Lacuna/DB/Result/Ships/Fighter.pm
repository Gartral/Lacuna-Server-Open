package Lacuna::DB::Result::Ships::Fighter;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq         => { class=> 'Lacuna::DB::Result::Building::PilotTraining',  level => 5 };
use constant base_food_cost      => 1000;
use constant base_water_cost     => 2600;
use constant base_energy_cost    => 16200;
use constant base_ore_cost       => 14200;
use constant base_time_cost      => 14600;
use constant base_waste_cost     => 4200;
use constant pilotable      => 1;

sub arrive {
    my ($self) = @_;
    $self->land;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);