package GPIBApp::Controller::Ws;
use Mojo::Base 'Mojolicious::Controller';
use DateTime;
use Data::Dumper;

my $clients = {};
my $socket;

# Websocket echo
sub echo {
    my $self = shift;

	
    $self->app->log->debug(sprintf 'Client connected to server: %s', $self->tx);
    my $id = sprintf "%s", $self->tx;
	print "Client connected: id=$id\n";
    $clients->{$id} = $self->tx;

    # Increase inactivity timeout for connection a bit
    $self->inactivity_timeout(800);


    $self->on(message => sub {
        my ($self, $msg) = @_;

        my $dt   = DateTime->now( time_zone => 'Europe/Amsterdam');
        $self->app->log->debug('Ws.pm:message: server received onmessage:' 
												. $msg );

        for (keys %$clients) {
        	$self->app->log->debug('Ws.pm:message: send to client\n' ) ;
            $clients->{$_}->send({json => {
                author  => $dt->hms,
                message => $msg,
            }});
        }
    });

    $self->on(finish => sub {
        $self->app->log->debug('Ws.pm:finish: Client disconnected');
        delete $clients->{$id};
    });

    $self->app->log->debug(sprintf 'Ws.pm: end of echo' ); 
};
1;
