package Lacuna::DB::Result::Building::Permanent;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
