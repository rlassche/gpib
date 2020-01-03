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

# POST
sub getDeviceInfo {
	my $self = shift;
	my $json = $self->req->body;
	my $h = decode_json( $json ) ;
  	$self->app->log->info('Controller::Rest.getDeviceInfo' . Dumper( $h ) ) ;
	my $gpib = $self->SDCGPIBHLP->{SDCGPIB} ;
	my $rv = $gpib->getDeviceInfo( { DEVICE_ID => '3456A' } );
  	$self->app->log->info('getDeviceInfo' . Dumper( $rv ) ) ;

    $self->render(json =>  $rv ) ;
}
# POST
sub taGetDevice {
	my $self = shift;
	my $json = $self->req->body;
	my $h = decode_json( $json ) ;

  	$self->app->log->info('Controller::Rest.taGetDevice' . Dumper( $h ) ) ;
	my $gpib = $self->SDCGPIBHLP->{SDCGPIB} ;

	my $rv = $gpib->taGetDevice( { DESCRIPTION => $h->{FORM_FIELDS}->{DEVICE_ID} } );
  	$self->app->log->info('taGetDevice' . Dumper( $rv ) ) ;

    $self->render(json =>  $rv ) ;
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
