package GPIBApp::Controller::Ws;
use Mojo::Base 'Mojolicious::Controller';
use DateTime;
use Data::Dumper;

my $clients = {};

# Websocket echo
sub echo {
    my $self = shift;

    $self->app->log->debug(sprintf 'Client connected to server: %s', $self->tx);
    my $id = sprintf "%s", $self->tx;
	print "Client connected: id=$id\n";
    $clients->{$id} = $self->tx;

    # Increase inactivity timeout for connection a bit
    $self->inactivity_timeout(300);


    $self->on(message => sub {
        my ($self, $msg) = @_;

        my $dt   = DateTime->now( time_zone => 'Asia/Tokyo');
        $self->app->log->debug('server received onmessage: ' . $msg );

        for (keys %$clients) {
            $clients->{$_}->send({json => {
                hms  => $dt->hms,
                text => $msg,
            }});
        }
    });

    $self->on(finish => sub {
        $self->app->log->debug('Client disconnected');
        delete $clients->{$id};
    });

};
1;
