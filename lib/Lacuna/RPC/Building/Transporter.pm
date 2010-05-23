package Lacuna::RPC::Building::Transporter;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/transporter';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Transporter';
}

no Moose;
__PACKAGE__->meta->make_immutable;
