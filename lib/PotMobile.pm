package PotMobile;
use Mojo::Base 'Mojolicious';
use Mojo::UserAgent;
use Mojo::JSON qw(decode_json encode_json);
use Mojolicious::Static;
use Mojolicious::Sessions;
use Mojo::UserAgent;
use Mojo::Redis2;


# This method will run once at server start
sub startup {
  my $self = shift;
  my $ua = Mojo::UserAgent->new;
	my $redis = Mojo::Redis2->new;

  # Load configuration from hash returned by "my_app.conf"
  my $config = $self->plugin('Config');

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer') if $config->{perldoc};
  $self->plugin('DebugDumperHelper');
  $self->plugin ('proxy');
  
  my $sessions = Mojolicious::Sessions->new;
	$sessions->cookie_name('pot_mobile');
	$sessions->default_expiration(86400);
  
  $self->log->path('/home/node/log/pot_mobile.log');

  # Router
  my $r = $self->routes;
  
  $r->websocket('/wsapi')->to('system#wsapi');
  $r->options('/*')->to('system#options');

  # Normal route to controller
  $r->any('/')->to('system#start');
  $r->get('/search/*search')->to('system#search');
  $r->get('/add_search_doc')->to('system#add_search_doc');
  $r->any('/dev/*file')->to('system#static');
	$r->get('/ipfs/:id')->to('system#ipfs');
  $r->get('/ipfs/:id/*file')->to('system#ipfs');
  
}

1;
