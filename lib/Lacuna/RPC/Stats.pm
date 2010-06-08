package Lacuna::RPC::Stats;

use Moose;
extends 'Lacuna::RPC';
use Lacuna::Constants qw(SHIP_TYPES);

sub credits {
    return [
            { 'Game Design'         => ['JT Smith','Jamie Vrbsky']},
            { 'Web Client'          => ['John Rozeske']},
            { 'iPhone Client'       => ['Kevin Runde']},
            { 'Game Server'         => ['JT Smith']},
            { 'Art and Icons'       => ['Ryan Knope','JT Smith','Joseph Wain / glyphish.com','Keegan Runde']},
            { 'Geology Consultant'  => ['Geofuels, LLC / geofuelsllc.com']},
            { 'Playtesters'         => ['John Oettinger','Jamie Vrbsky','Mike Kastern','Chris Burr','Eric Patterson','Frank Dillon','Kristi McCombs','Ryan McCombs','Mike Helfman','Tavis Parker','Sarah Bownds']},
            { 'Game Support'        => ['Plain Black Corporation / plainblack.com']},
            ];
}

sub overview {
    my ($self, $session_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $db = Lacuna->db;
    my %out = (
        stars               => $db->resultset('Lacuna::DB::Result::Map::Star')->count,
        bodies              => $db->resultset('Lacuna::DB::Result::Map::Body')->count,
        ships               => $db->resultset('Lacuna::DB::Result::Ships')->count,
        spies               => $db->resultset('Lacuna::DB::Result::Spies')->count,
        buildings           => $db->resultset('Lacuna::DB::Result::Building')->count,
        empires             => $db->resultset('Lacuna::DB::Result::Empire')->count,
    );
    return {
        status  => $self->format_status($empire),
        stats   => \%out,
    };
}

sub buildings_overview {
    my ($self, $session_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $empire_count = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->count;
    my $planet_count = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({empire_id => { '>' => 0}})->count;
    my $buildings = Lacuna->db->resultset('Lacuna::DB::Result::Building');
    my %out = ();
    my $distinct = $buildings->search(undef, { select => [ distinct => 'class' ] })->get_column('class');
    while (my $class = $distinct->next) {
        my $type_rs = $buildings->search({class=>$class});
        my $count = $type_rs->count;
        $out{$class->name} = {
            average_level       => $type_rs->get_column('level')->func('avg'),
            highest_level       => $type_rs->get_column('level')->max,
            per_empire          => $count / $empire_count,
            per_planet          => $count / $planet_count,
            count               => $count
        };
    }
    return {
        status  => $self->format_status($empire),
        stats   => \%out,
    };
}

sub ships_overview {
    my ($self, $session_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $empire_count = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->count;
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships');
    my %out = ();
    foreach my $type (SHIP_TYPES) {
        my $type_rs = $ships->search({type=>$type});
        my $count = $type_rs->count;
        $out{$type} = {
            average_hold_size   => $type_rs->get_column('hold_size')->func('avg'),
            largest_hold_size   => $type_rs->get_column('hold_size')->max,
            smallest_hold_size  => $type_rs->get_column('hold_size')->min,
            average_speed       => $type_rs->get_column('speed')->func('avg'),
            fastest_speed       => $type_rs->get_column('speed')->max,
            slowest_speed       => $type_rs->get_column('speed')->min,
            per_empire          => $count / $empire_count,
            count               => $count
        };
    }
    return {
        status  => $self->format_status($empire),
        stats   => \%out,
    };
}

sub empires_overview {
    my ($self, $session_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire');
    my $planets = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({class => {like => 'Lacuna::DB::Result::Map::Body::Planet%'}});
    my %out = (
        empires                     => $empires->count,
        average_university_level    => $empires->get_column('university_level')->func('avg'),
        highest_university_level    => $empires->get_column('university_level')->max,
        human_empires               => $empires->search({species_id => 2})->count,
        isolationist_empires        => $empires->search({is_isolationist => 1})->count,
        essentia_using_empires      => $empires->search({essentia => { '>' => 0 }})->count,
        currently_active_empires    => $empires->search({last_login => {'>=' => DateTime->now->subtract(hours=>1)}})->count,
        active_today_empires        => $empires->search({last_login => {'>=' => DateTime->now->subtract(hours=>24)}})->count,
        active_this_week_empires    => $empires->search({last_login => {'>=' => DateTime->now->subtract(days=>7)}})->count,
    );
    $out{planets_per_empire} = $planets->search({empire_id => { '>' => 0}})->count / $out{empires};
    return {
        status  => $self->format_status($empire),
        stats   => \%out,
    };
}

sub stars_overview {
    my ($self, $session_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $stars = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star');
    my $probes = Lacuna->db->resultset('Lacuna::DB::Result::Probes');
    my %out = (
        stars               => $stars->count,
        probes              => $probes->count,
        stars_probed        => $probes->search(undef, { select => [ distinct => 'star_id' ] })->count,
    );
    $out{probes_per_star} = $out{probes} / $out{stars_probed};
    return {
        status  => $self->format_status($empire),
        stats   => \%out,
    };
}

sub spies_overview {
    my ($self, $session_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies');
    my $empire_count = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->count;
    my $spy_count = $spies->count;
    my %out = (
        spies                           => $spy_count,
        average_defense                 => $spies->get_column('defense')->func('avg'),
        average_offense                 => $spies->get_column('offense')->func('avg'),
        highest_defense                 => $spies->get_column('defense')->max,
        highest_offense                 => $spies->get_column('offense')->max,
        spies_per_empire                => $spy_count / $empire_count,
        spies_gathering_intelligence    => $spies->search({task => 'Gather Intelligence'})->count,
        spies_hacking_networks          => $spies->search({task => 'Hack Networks'})->count,
        spies_countering_espionage      => $spies->search({task => 'Counter Espionage'})->count,
        spies_inciting_rebellion        => $spies->search({task => 'Incite Rebellion'})->count,
        spies_sabotaging_infrastructure => $spies->search({task => 'Sabotage Infrastructure'})->count,
        spies_appropriating_technology  => $spies->search({task => 'Appropriate Technology'})->count,
        spies_travelling                => $spies->search({task => 'Travelling'})->count,
        spies_training                  => $spies->search({task => 'Training'})->count,
        spies_in_prison                 => $spies->search({task => 'Captured'})->count,
        spies_unconscious               => $spies->search({task => 'Unconscious'})->count,
        spies_idle                      => $spies->search({task => 'Idle'})->count,
    );
    return {
        status  => $self->format_status($empire),
        stats   => \%out,
    };
}

sub bodies_overview {
    my ($self, $session_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $bodies = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body');

    # gas giants
    my $type = $bodies->search({class => {like => 'Lacuna::DB::Result::Map::Body::Planet::GasGiant%'}});
    my %gas_giants = (
        count           => $type->count,
        average_size    => $type->get_column('size')->func('avg'),
        largest_size    => $type->get_column('size')->max,
        smallest_size   => $type->get_column('size')->max,
        average_orbit   => $type->get_column('orbit')->func('avg'),
    );

    # habitables
    $type = $bodies->search({class => {like => 'Lacuna::DB::Result::Map::Body::Planet::P%'}});
    my %habitables = (
        count           => $type->count,
        average_size    => $type->get_column('size')->func('avg'),
        largest_size    => $type->get_column('size')->max,
        smallest_size   => $type->get_column('size')->max,
        average_orbit   => $type->get_column('orbit')->func('avg'),
    );
    
    # asteroids
    $type = $bodies->search({class => {like => 'Lacuna::DB::Result::Map::Body::Asteroid%'}});
    my %asteroids = (
        count           => $type->count,
        average_size    => $type->get_column('size')->func('avg'),
        largest_size    => $type->get_column('size')->max,
        smallest_size   => $type->get_column('size')->max,
        average_orbit   => $type->get_column('orbit')->func('avg'),
    );
    
    # stations
    $type = $bodies->search({class => 'Lacuna::DB::Result::Map::Body::Station'});
    my %stations = (
        count           => $type->count,
        average_size    => $type->get_column('size')->func('avg'),
        largest_size    => $type->get_column('size')->max,
        smallest_size   => $type->get_column('size')->max,
        average_orbit   => $type->get_column('orbit')->func('avg'),
    );
    
    # oribts
    my %orbits;
    foreach my $orbit (1..8) {
        $orbits{$orbit} = {
            inhabited   => $bodies->search({empire_id => {'>', 0}, orbit => $orbit})->count,
            bodies      => $bodies->search({orbit => $orbit})->count,
        }
    }
    
    # out
    return {
        status  => $self->format_status($empire),
        stats   => {
            bodies      => $bodies->count,
            habitables  => \%habitables,
            asteroids   => \%asteroids,
            stations    => \%stations,
            gas_giants  => \%gas_giants,
            orbits      => \%orbits,
        },
    };
}

sub empire_rank {
    my ($self, $session_id, $by, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    unless ($by ~~ [qw(empire_size_rank university_level_rank offense_success_rate_rank defense_success_rate_rank dirtiest_rank)]) {
        $by = 'empire_size_rank';
    }
    my $ranks = Lacuna->db->resultset('Lacuna::DB::Result::Log::Empire')->search(undef,{order_by => {-desc => $by}});
    unless ($page_number) {
        my $me = $ranks->find($empire->id);
        $page_number = int($me->$by / 25);
        if ( $me->$by % 25 ) {
            $page_number++;
        }
    }
    $ranks = $ranks->search(undef,{rows => 25, page => $page_number});
    my @empires;
    while (my $rank = $ranks->next) {
        push @empires, {
            empire_id                   => $rank->empire_id,
            empire_name                 => $rank->empire_name,
            colony_count                => $rank->colony_count,
            colony_count_delta          => $rank->colony_count_delta,
            population                  => $rank->population,
            population_delta            => $rank->population_delta,
            empire_size                 => $rank->empire_size,
            empire_size_delta           => $rank->empire_size_delta,
            building_count              => $rank->building_count,
            university_level            => $rank->university_level,
            average_building_level      => $rank->average_building_level,
            highest_building_level      => $rank->highest_building_level,
            food_hour                   => $rank->food_hour,
            energy_hour                 => $rank->energy_hour,
            waste_hour                  => $rank->waste_hour,
            ore_hour                    => $rank->ore_hour,
            water_hour                  => $rank->water_hour,
            happiness_hour              => $rank->happiness_hour,
            spy_count                   => $rank->spy_count,
            offense_success_rate        => $rank->offense_success_rate,
            offense_success_rate_delta  => $rank->offense_success_rate_delta,
            defense_success_rate        => $rank->defense_success_rate,
            defense_success_rate_delta  => $rank->defense_success_rate_delta,
            dirtiest                    => $rank->dirtiest,
            dirtiest_delta              => $rank->dirtiest_delta,
        };
    }
    return {
        status  => $self->format_status($empire),
        empires => \@empires,
    };
}

sub find_empire_rank {
    my ($self, $session_id, $by, $empire_name) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    unless ($by ~~ [qw(empire_size_rank university_level_rank offense_success_rate_rank defense_success_rate_rank dirtiest_rank)]) {
        $by = 'empire_size_rank';
    }
    my $ranks = Lacuna->db->resultset('Lacuna::DB::Result::Log::Empire')->search(undef,{order_by => {-desc => $by}, rows=>25});
    my $ranked = $ranks->search({empire_name => { like => '%'.$empire_name.'%'}});
    my @empires;
    while (my $rank = $ranked->next) {
        my $page_number = int($rank->$by / 25);
        if ( $rank->$by % 25 ) {
            $page_number++;
        }
        push @empires, {
            empire_id   => $rank->empire_id,
            empire_name => $rank->empire_name,
            page_number => $rank->page_number,
        };
    }
    return {
        status  => $self->format_status($empire),
        empires => \@empires,
    };
}

sub colony_rank {
    my ($self, $session_id, $by, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    unless ($by ~~ [qw(population_rank)]) {
        $by = 'population_rank';
    }
    my $ranks = Lacuna->db->resultset('Lacuna::DB::Result::Log::Colony')->search(undef,{order_by => {-desc => $by}});
    my @colonies;
    while (my $rank = $ranks->next) {
        push @colonies, {
            empire_id                   => $rank->empire_id,
            empire_name                 => $rank->empire_name,
            planet_id                   => $rank->planet_id,
            planet_name                 => $rank->planet_name,
            population                  => $rank->population,
            population_delta            => $rank->population_delta,
            building_count              => $rank->building_count,
            average_building_level      => $rank->average_building_level,
            highest_building_level      => $rank->highest_building_level,
            food_hour                   => $rank->food_hour,
            energy_hour                 => $rank->energy_hour,
            waste_hour                  => $rank->waste_hour,
            ore_hour                    => $rank->ore_hour,
            water_hour                  => $rank->water_hour,
            happiness_hour              => $rank->happiness_hour,
            spy_count                   => $rank->spy_count,
            offense_success_rate        => $rank->offense_success_rate,
            offense_success_rate_delta  => $rank->offense_success_rate_delta,
            defense_success_rate        => $rank->defense_success_rate,
            defense_success_rate_delta  => $rank->defense_success_rate_delta,
            dirtiest                    => $rank->dirtiest,
            dirtiest_delta              => $rank->dirtiest_delta,
        }
    }
    return {
        status      => $self->format_status($empire),
        colonies    => \@colonies,
    };
}

sub find_colony_rank {
    my ($self, $session_id, $by, $colony_name) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    unless ($by ~~ [qw(population_rank)]) {
        $by = 'population_rank';
    }
    my $ranks = Lacuna->db->resultset('Lacuna::DB::Result::Log::Colony')->search(undef,{order_by => {-desc => $by}, rows=>25});
    my $ranked = $ranks->search({planet_name => { like => '%'.$colony_name.'%'}});
    my @colonies;
    while (my $rank = $ranked->next) {
        my $page_number = int($rank->$by / 25);
        if ( $rank->$by % 25 ) {
            $page_number++;
        }
        push @colonies, {
            page_number => $rank->page_number,
            planet_name => $rank->planet_name,
            planet_id   => $rank->planet_id,
        };
    }
    return {
        status      => $self->format_status($empire),
        colonies    => \@colonies,
    };
}

sub spy_rank {
    my ($self, $session_id, $by, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    unless ($by ~~ [qw(level_rank success_rate_rank dirtiest_rank)]) {
        $by = 'level_rank';
    }
    my $ranks = Lacuna->db->resultset('Lacuna::DB::Result::Log::Spies')->search(undef,{order_by => {-desc => $by}});
    my @spies;
    while (my $rank = $ranks->next) {
        push @spies, {
            empire_id                   => $rank->empire_id,
            empire_name                 => $rank->empire_name,
            spy_id                      => $rank->spy_id,
            spy_name                    => $rank->spy_name,
            age                         => $rank->level,
            level                       => $rank->level,
            level_delta                 => $rank->level_delta,
            success_rate                => $rank->success_rate,
            success_rate_delta          => $rank->success_rate_delta,
            dirtiest                    => $rank->dirtiest,
            dirtiest_delta              => $rank->dirtiest_delta,
        }
    }
    return {
        status      => $self->format_status($empire),
        spies       => \@spies,
    };
}

sub find_spy_rank {
    my ($self, $session_id, $by, $spy_name) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    unless ($by ~~ [qw(level_rank success_rate_rank dirtiest_rank)]) {
        $by = 'level_rank';
    }
    my $ranks = Lacuna->db->resultset('Lacuna::DB::Result::Log::Spies')->search(undef,{order_by => {-desc => $by}, rows=>25});
    my $ranked = $ranks->search({spy_name => { like => '%'.$spy_name.'%'}});
    my @spies;
    while (my $rank = $ranked->next) {
        my $page_number = int($rank->$by / 25);
        if ( $rank->$by % 25 ) {
            $page_number++;
        }
        push @spies, {
            page_number => $rank->page_number,
            spy_name    => $rank->spy_name,
            empire_name => $rank->empire_name,
            spy_id      => $rank->spy_id,
        };
    }
    return {
        status  => $self->format_status($empire),
        spies   => \@spies,
    };
}

    
__PACKAGE__->register_rpc_method_names(qw(find_spy spy_rank find_colony_rank colony_rank find_empire_rank empire_rank credits overview bodies_overview spies_overview stars_overview empires_overview buildings_overview ships_overview));

no Moose;
__PACKAGE__->meta->make_immutable;

