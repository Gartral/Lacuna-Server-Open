package Lacuna::DB::Result::Ships::Freighter;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';


use constant prereq         => { class=> 'Lacuna::DB::Result::Building::Trade',  level => 20 };
use constant base_food_cost      => 3600;
use constant base_water_cost     => 10800;
use constant base_energy_cost    => 36000;
use constant base_ore_cost       => 61000;
use constant base_time_cost      => 15000;
use constant base_waste_cost     => 4800;
use constant base_speed     => 800;
use constant base_stealth   => 1000;
use constant base_hold_size => 1905;
use constant pilotable      => 1;

sub arrive {
    my ($self) = @_;
    unless ($self->capture_with_spies) {
        $self->handle_cargo_exchange;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);