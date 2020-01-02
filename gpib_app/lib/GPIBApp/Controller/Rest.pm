package GPIBApp::Controller::Rest;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
use JSON::XS;
use DBIx::Connector;
use Database;
use SDC::GPIB;


# This action will render a template
sub welcome {
  my $self = shift;

  # Render template "example/welcome.html.ep" with message
  $self->render(msg => 'Welcome to the Mojolicious real-time web framework!');
}

sub gpibDevices {
	my $json = $self->req->body;
	my $h = decode_json( $json ) ;

	my $db = $self->DATABASEHLP->{DATABASE} ;
}

sub version {
  my $self = shift;

  my( $db, $u, $rv, $m, %response ) ;

  #my $config = $self->plugin('Config');

  $self->app->log->info('Controller::Rest.version' ) ;

  # Get the Helpers
  $db = $self->DATABASEHLP->{DATABASE} ;

  $self->render(json => {
                STATUS   => "OK",
                PERL => [ $db->version() ]
				});
}

1;
