#!/usr/bin/perl

#########################
##
##	CitiBike CLI
##	Zill Christian
##
#########################

use strict;
use warnings;
use 5.010;
use LWP::UserAgent;
use JSON qw( decode_json );

use constant false => 0;
use constant true  => 1;

my $action = shift || 'park';

my $ip = '0.0.0.0';
my $lat = "0";
my $lng = "0";
my $stop = false;
my $freq = 5;

# init
main();

sub main {
	checkArgs() || exit;;
	getLocation();

	while (!$stop) {
		getCitiData();
		sleep($freq);
	}
}

sub getCitiData {
	# TODO
}

sub getLocation {
	my $endpoint = "http://ipinfo.io/json";
	my $userAgent = LWP::UserAgent->new;
    my $req = HTTP::Request->new(GET => $endpoint);
    my $resp = $userAgent->request($req);

    if ($resp->is_success) {
    	my $message = $resp->decoded_content;
        my $json = decode_json($message);
        my $loc = "";

        # Collecting ip address
        if (exists $json->{'ip'} eq 1) {
        	$ip = $json->{'ip'};
        }
        
        # Collecting location
        if (exists $json->{'loc'} eq 1) {
        	$loc = $json->{'loc'};
        } else {
        	print "Critial Error: Could not collect your location!";
        	exit;;
        }

        # Splitting string and getting lat/lng
        ($lat, $lng) = split(/,/, $loc);
    }
}

sub checkArgs {
	if ($action eq "park" || $action eq "find") {
		return true;
	}

	print "Please specify action: park or find";
	return false;
}

sub clearScreen {
	system $^O eq 'MSWin32' ? 'cls' : 'clear';
}