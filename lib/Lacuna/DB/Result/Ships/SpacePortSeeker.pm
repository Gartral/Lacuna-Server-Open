package Lacuna::DB::Result::Ships::SpacePortSeeker;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq         => { class=> 'Lacuna::DB::Result::Building::DemolitionLab',  level => 15 };
use constant base_food_cost      => 20000;
use constant base_water_cost     => 50000;
use constant base_energy_cost    => 300000;
use constant base_ore_cost       => 350000;
use constant base_time_cost      => 58500;
use constant base_waste_cost     => 80000;
use constant base_speed     => 1000;
use constant base_stealth   => 2000;


sub arrive {
    my ($self) = @_;
    unless ($self->trigger_defense) {
        $self->damage_building($self->foreign_body->get_building_of_class('Lacuna::DB::Result::Building::SpacePort'));
    }
}

sub can_send_to_target {
    my ($self, $target) = @_;
    confess [1009, 'Can only be sent to planets.'] unless ($target->isa('Lacuna::DB::Result::Map::Body::Planet'));
    confess [1013, 'Can only be sent to inhabited planets.'] unless ($target->empire_id);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);