package GPIBApp;
use Mojo::Base 'Mojolicious';
use Mojolicious::Plugin::Database;
use Database;
use Data::Dumper;


# This method will run once at server start
sub startup {
  my $self = shift;

  # Load configuration from hash returned by config file
  my $config = $self->plugin('Config');

  # Configure the application
  $self->secrets($config->{secrets});

# load and configure
  $self->plugin('SecureCORS');
  $self->plugin('SecureCORS', { max_age => undef});
  # set app-wide CORS defaults
  $self->routes->to('cors.credentials'=>1);


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

  my $x = $self->db ;
  $self->app->log->info( 'plugin database' . Dumper( $x )) ;

  my $db = new Database(
                     DBH => $self->db,
                     LOG4DB => 1,
                     LOG_LEVEL=>"FATAL",
                     LOG_CLASS => "testDatabase" );

  $self->app->helper( DATABASEHLP => sub {
            return { DATABASE => $db }
        }) ;

  # Router
  my $r = $self->routes;

  $self->routes->to('cors.origin'=>'*');
  $self->routes->to('cors.methods'=>'GET,POST,PUT,DELETE,OPTION,OPTIONS');
  $self->routes->to('cors.headers'=>'content-type,Access-Control-Allow-Origin');

  # Normal route to controller
  $r->get('/')->to('example#welcome');
}

1;
