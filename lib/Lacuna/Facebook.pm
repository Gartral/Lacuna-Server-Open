package Lacuna::Facebook;

use Moose;
extends qw(Plack::Component);
use Plack::Request;
use Facebook::Graph;
use LWP::UserAgent;

has facebook => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $config = Lacuna->config;
        return Facebook::Graph->new(
            postback    => $config->get('server_url').'facebook/oauth',
            app_id      => $config->get('facebook/app_id'),
            secret      => $config->get('facebook/secret'),
        );
    },
);

sub call {
    my ($self, $env) = @_;
    my $request = Plack::Request->new($env);

    # figure out what is being called
    my $method_name = $request->path_info;
    $method_name =~ s{^/}{};                # remove preceeding slash
    $method_name =~ s{/}{_}g;               # replace slashes with underscores
    $method_name ||= 'default';             # if no method is specified, then display the default
    $method_name = 'www_' . $method_name;   # not all methods are public
    
    # call it
    my $out;
    my $method = $self->can($method_name);
    if ($method) {
        $out = eval{$self->$method($request)};
        if ($@) {
            $out = $self->format_error($request, $@);
        }
    }

    # process response
    my $response = $request->new_response;
    if ($out->[1]{status} eq 302) {
        $response->redirect($out->[0]);
    }
    else {
    	$response->status($out->[1]{status} || 200);
        $response->content_type($out->[1]{content_type} || 'text/html');
        $response->body($out->[0]);
    }
    return $response->finalize;
}

sub www_oauth {
    my ($self, $request) = @_;
    my $config = Lacuna->config;
    my $url = sprintf('https://graph.facebook.com/oauth/access_token?client_id=%s&redirect_uri=https://alpha.lacunaexpanse.com/facebook/oauth&client_secret=%s&code=%s',
        $config->get('facebook/app_id'),
        $config->get('facebook/secret'),
        $request->param('code'), 
    );
    my $response = $self->user_agent->get($url);
    my $uri = URI->new('?'.$response->content);
    my $out;
    foreach my $key ($uri->query_param) {
       $out .= $key.': '.join(", ", $uri->query_param($key)).'<br>';
    }
    return [ $out ];
}

sub www_post_authorize {
    my ($self, $request) = @_;
    return [$self->wrapper('post authorize')];
}

sub www_post_remove {
    my ($self, $request) = @_;
    return [$self->wrapper('post remove')];
}


sub get_session {
    my ($self, $session_id) = @_;
    if (ref $session_id eq 'Lacuna::DB::Result::Session') {
        return $session_id;
    }
    else {
        my $session = Lacuna::Session->new(id=>$session_id);
        if ($session->empire_id) {
            $session->extend;
            return $session;
        }
        else {
            return undef;
        }
    }
}

sub www_authorize {
    my ($self, $request) = @_;
    my $config = Lacuna->config;
    return ['https://graph.facebook.com/oauth/authorize?client_id='.$config->get('facebook/app_id').'&redirect_uri=https://alpha.lacunaexpanse.com/facebook/oauth&scope=email,publish_stream,offline_access', { status => 302 }];
    my $session = $self->get_session($request->param('session_id'));
    unless (defined $session) {
        return [$self->wrapper('You must be logged in to purchase essentia.'), { status => 401 }];
    }
    my $empire = $session->empire;
    unless (defined $empire) {
        return [$self->wrapper('Empire not found.'), { status => 401 }];
    }
    return [$self->wrapper('<iframe frameborder="0" scrolling="no" width="425" height="365" src="'.$self->jambool_buy_url($empire->id).'"></iframe>')];
}

sub www_default {
    my ($self, $request) = @_;
    my $cache = Lacuna->cache;
    my $servers = $cache->get_and_deserialize('www.lacunaexpanse.com', 'servers.json');
    unless (defined $servers && ref $servers eq 'ARRAY') {
        my $servers_json = LWP::UserAgent->new->get('http://www.lacunaexpanse.com/servers.json')->content;
        $servers = JSON->new->decode($servers_json);
        $cache->set('www.lacunaexpanse.com', 'servers.json', $servers, 60 * 60 * 24);
    }
    my $template = '<a href="%s" class="server_button">
<div class="server_name_label">Server</div>
<div class="server_name">%s</div>
<div class="location_label">Location</div>
<div class="location">%s</div>
<div class="status_label">Status</div>
<div class="status">%s</div>
<div class="play_now">Play Now!</div>
</a>
';
    my $out = '<img src="https://s3.amazonaws.com/alpha.lacunaexpanse.com/assets/ui/logo.png" style="margin-left: 50px;">
<div style="font-size: 50px; margin-left: 140px; font-family: Helvetica; color: white;">Available Servers</div>';
    foreach my $server (@{$servers}) {
        $out .= sprintf $template, $server->{uri}, $server->{name}, $server->{location}, $server->{status};
    }
    return $self->wrapper('Choose A Server', $out);
}

sub format_error {
    my ($self, $request, $error) = @_;
    unless (ref $error eq 'ARRAY') {
        $error = [$error];
    }
    my $out = '<h1>Error</h1> '. $error->[0] . ' <hr> ';
    if (ref $request eq 'Plack::Request') {
        foreach my $key ($request->parameters->keys) {
            $out .= $key.': '.$request->param($key).'<br>';
        }
    }
    else {
        $out .= 'No request object!';
    }
    return [$self->wrapper($out), {status => $error->[1] || 500}];
}

sub wrapper {
    my ($self, $title, $content) = @_;
    if (open my $file, "<", '/data/Lacuna-Server/var/wrapper.html') {
        my $html;
        {
            local $/;
            $html = <$file>;
        }
        close $file;
        return sprintf $html, $title, $content;    
    }
    return 'Could not open wrapper template.';    
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

