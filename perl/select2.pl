#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  select2.pl
#
#        USAGE:  ./select2.pl  
#
#  DESCRIPTION:  select2
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Rob Lassche (mn), rob@pd1rla.nl
#      COMPANY:  Me
#      VERSION:  1.0
#      CREATED:  01/06/2020 10:01:28 AM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;


use IO::Select;
use Data::Dumper;

my( $sel, $fh, $some_handle, $timeout, $line, @ready, @handles);
$sel = IO::Select->new();
$sel->add(\*STDIN);

while(@ready = $sel->can_read) {
        foreach $fh (@ready) {
            if($fh == \*STDIN) {
                $line=<STDIN>;
                print "STDIN: $line\n" ;
            }
            else {
                print "Hu?\n" ;
            }
        }
}

