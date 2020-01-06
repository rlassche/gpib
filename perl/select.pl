#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  select.pl
#
#        USAGE:  ./select.pl  
#
#  DESCRIPTION:  Test script for 'select'
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Rob Lassche (mn), rob@pd1rla.nl
#      COMPANY:  Me
#      VERSION:  1.0
#      CREATED:  01/06/2020 09:22:49 AM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use IO::Select;
use IO::Handle;
use Data::Dumper;

my $timeout=10;
print "Please type characters and end with ENTER, or wait $timeout seconds: " ;

my $s = IO::Select->new() ;

my $io=IO::Handle->new() ;
print 'fileno STDIN: ' . fileno( STDIN ) . '\n';
exit;
my $rin = my $win = my $ein = '';
vec($rin, fileno(STDIN),  1) = 1;
vec($win, fileno(STDOUT), 1) = 1;

#my $buffer; 
#read( <STDIN>, $buffer, 2 ) ;
#print "BUFFER: $buffer\n" ;
#$s->add( \*STDIN ); 
#$s->add( *STDIN ); 
#$s->add( <\*STDIN> ); 
#$s->add( 1 ); 

my @ready = $s->can_read( $timeout ) ;
print ".\n". Dumper( $ready[0] ). "\n" ;
#my $text = <STDIN>;
#my $text = $ready[0];
#read( $ready[0], $buffer, 100 ) ;
#print "Bye: $buffer\n" ;
