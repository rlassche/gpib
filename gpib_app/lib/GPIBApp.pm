package GPIBApp;
use Mojo::Base 'Mojolicious';
use Mojolicious::Plugin::Database;
use Database;
use Data::Dumper;
use SDC::GPIB;
#use Mojo::Transaction::WebSocket;
#

use Socket;
use IO::Socket::INET;
use IO::Select;

my $port   = 7777;
my $server = 'localhost';


my $clients = {} ;
# This method will run once at server start
sub startup {
	my $self = shift;

	my $socket;

	# Load configuration from hash returned by config file
	my $config = $self->plugin('Config');

	# Configure the application
	$self->secrets($config->{secrets});

	# load and configure
	$self->plugin('SecureCORS');
	$self->plugin('SecureCORS', { max_age => undef});
	# set app-wide CORS defaults
	$self->routes->to('cors.credentials'=>1);


	# create the socket, connect to the port
    socket($socket,PF_INET,SOCK_STREAM,(getprotobyname('tcp'))[2])
       or die "Can't create a socket $!\n";
    connect( $socket, pack_sockaddr_in($port, inet_aton($server)))
       or die "Can't connect to port $port! \n";
    $socket->autoflush;

	my $s = IO::Select->new() ;

	$s->add( $socket );
	$self->app->helper( SOCKETHLP => sub {
            return { SOCKET => $s }
        }) ;



	$self->app->log->info( 'dsn ' . $config->{dsn} ) ;
	$self->plugin( 'database', {
                     dsn => $config->{dsn},
                     username => $config->{user},
                     password => $config->{password},
                     options => {
                        RaiseError => 0,
                        mysql_auto_reconnect => 1,
                        AutoCommit => 1,
                        PrintError         => 0,
                        PrintWarn          => 0,
                     },
                     helper => 'db'
                });

	my $db = new Database(
                     DBH => $self->db,
                     LOG4DB => 1,
                     LOG_LEVEL=>"FATAL",
                     LOG_CLASS => "testDatabase" );

	my $gpib = new SDC::GPIB( DATABASE => $db ) ;
	#$self->app->log->info( 'gpib ' . Dumper( $gpib ) ) ;

	my $devices = { };
	$self->app->helper( DEVICESHLP => sub {
            return { DEVICES => $devices }
        }) ;

  $self->app->helper( DATABASEHLP => sub {
            return { DATABASE => $db }
        }) ;
  
  $self->app->helper( SDCGPIBHLP => sub {
            return { SDCGPIB => $gpib }
        }) ;

  # Router
  my $r = $self->routes;

  $self->routes->to('cors.origin'=>'*');
  $self->routes->to('cors.methods'=>'GET,POST,PUT,DELETE,OPTION,OPTIONS');
  $self->routes->to('cors.headers'=>'content-type,Access-Control-Allow-Origin');

  # Normal route to controller
  $r->get('/')->to('example#welcome');
  $r->post('/gpib/taGetDevice')->to('Rest#taGetDevice');
  $r->post('/gpib/getDeviceInfo')->to('Rest#getDeviceInfo');
  $r->post('/gpib/initDevice')->to('Rest#initDevice');
  $r->post('/gpib/sendToDevice')->to('Rest#sendToDevice');
  $r->post('/gpib/readFromDevice')->to('Rest#readFromDevice');
  $r->post('/gpib/documentation')->to('Rest#documentation');
  $r->get('/echo')->to('Ws#echo');
}

1;
