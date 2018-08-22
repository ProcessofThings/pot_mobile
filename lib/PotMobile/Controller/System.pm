package PotMobile::Controller::System;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON qw(decode_json encode_json);
use Mojo::Redis2;
use DBM::Deep;
use Devel::Size qw(total_size);


use Data::Dumper;

my $clients = {};
my $redis = Mojo::Redis2->new;

# This action will render a template
sub start {
  my $c = shift;
  my $jsonParams = $c->req->json;
  my $ipfsHash = '00000000-4D13-11E7-BE5F-0C6F1B433B3E';
  
  my $pubid = 'hf938hflaskdhflkasdhflaksdhfl';
  
  $c->session(pubid => $jsonParams->{'pubid'});
  
  # $c->redis->hset('user_'+$pubid, $blockchain, encode_json($status));
  
  my $data = '{ "containerid" : "263A40C2-8353-11E7-96CC-12B968665064", "attribs" : { "run" : { "other" : [{ "microservice" : "C8CF1BEE-4D13-11E7-BE5F-0C6F1B433B3E", "sequence" : "1", "description" : "Scan KO Code", "data" : { "next" : "89BE2F4C-506C-11E7-AE0F-AFE859AE2E83", "description" : "Scan KO Code", "loadlayout" : "A84362E8-6A70-11E7-98A4-084EF57E7A0C" } } ] }, "access" : { "groups" : [ "194BA3E4-7B86-11E7-B404-8F255FF2CFAC" ] }, "microservice" : "location", "collection" : "location" }, "template" : "tierone", "type" : "location", "cpu" : "989096a57336" }';

	$data = decode_json($data);
	
#	my $config = $ua->get('127.0.0.1:3000/dev/'.$ipfsHash.'/config.json')->result->body;
	my $config = '{"dapplet":"Recieving Goods","components": ["formGenerator"],"navitems":[{"action":"build","navitems":[{"href":"scan","title":"Scan"}]},{"action":"explore","navitems":[{"href":"displaydata","title":"Display"}]}]}';
	
	$config = decode_json($config);
	
	my $component;
	my @components;
	my $devdirectory = $c->config->{dev}.'/'.$ipfsHash;
	$c->app->log->debug($devdirectory);
	
	foreach my $item (@{$config->{'components'}}) {
		$c->debug($item);
		if (-d $devdirectory) {
			$c->app->log->debug("Developer Tool - Detected local copy");
			$component = $item.': httpVueLoader( "/dev/'.$ipfsHash.'/'.$item.'.vue" )';
		} else {
			$component = $item.': httpVueLoader( "/ipfs/'.$ipfsHash.'/'.$item.'.vue" )';
		}
		$c->config($component);
		push @components, $component;
	}

	$c->debug(@components);
	
	my $list = join(',',@components);
	
	$c->debug($list);
	
	$c->stash(import_components => $list);

  $c->render(template => 'system/start', status => 200);
}

sub static {
	my $c = shift;
	my $file = $c->param('file');
	my $pubid = $c->session('pubid');
	$c->debug($pubid);
	$file = $c->config->{dev}.'/'.$file;
	$c->res->content->asset(Mojo::Asset::File->new(path => $file));
  $c->rendered(200);
};

sub ipfs {
    my $c = shift;
    my $url = $c->req->url->to_string;
    my $id = $c->param('id');
    my $file = $c->param('file') || 'none';
    my $base;
    if ($file ne 'none') {
	$base = "http://127.0.0.1:8080/ipfs/$id/$file";
    } else {
	$base = "http://127.0.0.1:8080/ipfs/$id";
    }
    $c->app->log->debug("IPFS : $base");
    $c->proxy_to($base);
};

sub options {
	my $c = shift;
	$c->app->log->debug('OPTIONS');
	$c->res->headers->header('Access-Control-Allow-Origin' => '*');
	$c->res->headers->header('Access-Control-Allow-Headers' => 'session-key','Content-Type');
	$c->res->headers->header('Access-Control-Allow-Methods' => 'GET, POST, PUT, DELETE, OPTIONS');
	$c->render(json => {"message" => "Ok"},status => 200);
}

sub wsapi {
    my $c = shift;
    my $rsub;
    my $pong;
    my $pongkey;
    
 
#    $c->kept_alive;
    $c->inactivity_timeout(60);
    $c->app->log->debug("Open Websocket");
    $c->debug(sprintf 'Client connected: %s', $c->tx);
    my $id = sprintf "%s", $c->tx;
    $clients->{$id} = $c->tx;

    $c->on(message => sub {
		my ($self, $msg) = @_;
		$msg = decode_json($msg);
		
 		if ($msg->{'channel'} eq 'ping') {
			if ($c->redis->exists('pong')) {
              $pong = $c->redis->get('pong');
				  $pongkey = 	$c->redis->get('pongkey');
			} else {
					$pong = "__pong__";
					$pongkey = "1";
			}
 			$c->app->log->debug("Message : $pong");
 			my $wsconid = $c->tx->handshake->{'connection'};
#			$c->debug("WSCon".$wsconid);
 			$self->send({json => {
 				channel => "pong",
 				data => {
 					msg => $pong,
 					id => $pongkey
 				}
 			}});
 			return undef;
 		}

		$c->app->log->debug("Channel : $msg->{'channel'}");
		
		$rsub = $c->redis->subscribe([$msg->{'channel'}]);
		
		my $data;

		$rsub->on(message => sub {
			my ($rsub, $message, $channel) = @_;
			$c->app->log->debug("Subscribe Message");
			$message = decode_json($message);
			$data->{'channel'} = $channel;
			$data->{'data'} = $message;
			$self->send({json => $data});
			
		});
	});
};

sub createDoc {
	my $c = shift;
	my $db = DBM::Deep->new( 
		file => "/home/node/search/0001.db",
		type => DBM::Deep->TYPE_ARRAY
	);
	push(@$db, "123456-123-125 sn121ab2315 monitor keyboard");
	push(@$db, "123456-123-126 sn121bb2316 monitor keyboard");
	push(@$db, "123456-123-127 sn121cb2317 monitor hd");
	push(@$db, "123456-123-128 sn121db2318 monitor");
	
$c->render(text => "ok", status => 200);

};


sub search {
	use PotMobile::VectorSpace;
	my $start = time;
	my $db = DBM::Deep->new( 
		file => "/home/node/search/0001.db",
		type => DBM::Deep->TYPE_ARRAY
	);
	
	my $c = shift;
	
	my @docs = @$db;
	
	print "Size: ", total_size(\@docs), " bytes.\n";
	
	
	my $engine = PotMobile::VectorSpace->new( docs => \@docs, threshold => 0.4);
	$engine->build_index();
	my $search = $c->param('search');
	
	while ( my $query = $search ) {
				print Dumper($query);
        my %results = $engine->search( $query );
        foreach my $result ( sort { $results{$b} <=> $results{$a} }
                             keys %results ) {
                print "Relevance: ", $results{$result}, "\n";
                print $result, "\n\n";
        }


        print "Next query?\n";
        last;
    }
	my $end = time;
	my $elapsedtime = $end - $start;
	$c->render(text => "$elapsedtime", status => 200);
};

1;
