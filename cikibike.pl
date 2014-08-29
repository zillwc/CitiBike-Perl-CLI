#!/usr/bin/perl

##############################
##
##	CitiBike CLI
##	Zill Christian
##
##  MIT License
##
##############################

use strict;
use warnings;
use 5.010;
use LWP::UserAgent;
use JSON qw( decode_json );
use Data::Dumper;
use Getopt::Long;

use constant false => 0;
use constant true  => 1;

my $ip = '0.0.0.0';
my $lat = "0";
my $lng = "0";
my $stop = false;

my $action = "park";
my $freq = 15;

$|++;

GetOptions('a|action:s' =>\$action, 'f|freq:f' =>\$freq);

# init
main();

# Main init function
sub main {
	checkArgs() || exit;
	
	# Get user preference on location
	my $opt = 0;
	while (!($opt==1 || $opt==2)) {
		clearScreen();
		print "CitiBike CLI\n\nHow would you like me to find you? (1/2)\n1. Auto Find Me\n2. Enter Address\n\n:";
		$opt = <STDIN>;
	}

	# Parse user preference
	if ($opt==1) {
		my $fact = getAutoLocation();	# Auto find user location
	} else {
		getUserAddress();	# Have user enter their address
	}

	while (!$stop) {
		clearScreen();
		getCitiData();
        printCounter();
        startCounter();
	}
}

# Auto find the users location using their ip address
sub getAutoLocation {
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
        	exit;
        }

        # Splitting string and getting lat/lng
        ($lat, $lng) = split(/,/, $loc);
    } else {
    	print "Could not auto find your location";
    	exit;
    }
    return true;
}

# Ask the user to enter their address
sub getUserAddress {
	print "\nWhat is your address: ";
	my $userAddress = <STDIN>;
	if (getLocationFromAddress($userAddress)) {
		return true;
	} else {
		print "Could not find you!";
		exit;
	}
}

# Use google reverse location to get their lat and lng
sub getLocationFromAddress {
	my $address = shift;
	$address =~ s/\s/+/g;
	my $endpoint = "http://maps.googleapis.com/maps/api/geocode/json?address=".$address;
	my $userAgent = LWP::UserAgent->new;
    my $req = HTTP::Request->new(GET => $endpoint);
    my $resp = $userAgent->request($req);

    if ($resp->is_success) {
    	my $message = $resp->decoded_content;
        my $json = decode_json($message);

        if (exists $json->{'status'} eq 1) {
        	$lat = $json->{'results'}->[0]->{'geometry'}->{'location'}->{'lat'};
        	$lng = $json->{'results'}->[0]->{'geometry'}->{'location'}->{'lng'};
        	
        	chomp $lat;
        	chomp $lng;
    	} else {
    		print "Could not parse data from Google Maps server: 400 Bad Request";
    		exit;	
    	}
    } else {
    	print "Could not make handshake with google maps server: 500 Internal Server Error";
    	exit;
    }

    return true;
}

# Make request and collect station data from citi server
sub getCitiData {
	my $endpoint = "http://54.187.10.164/citi/v1/?lat=".$lat."&lng=".$lng."&action=".$action;
	my $userAgent = LWP::UserAgent->new;
    my $req = HTTP::Request->new(GET => $endpoint);
    my $resp = $userAgent->request($req);

    if ($resp->is_success) {
    	my $message = $resp->decoded_content;
        my $json = decode_json($message);
        
        if (exists $json->{'status'} eq 1) {
        	my $status = $json->{'status'};

        	if ($status eq 200) {
                my $stations = $json->{'stations'};
                my $len = @$stations;

                print "The $len closest stations to your location:\n\n";

                for (my $i=0; $i<$len; $i++) {
                    my $stationLabel = @$stations[$i]->{'label'};
                    my $bikesAvail = @$stations[$i]->{'available_bikes'};
                    my $docksAvail = @$stations[$i]->{'available_docks'};
                    my $distAway = sprintf("%.3f", @$stations[$i]->{'dist_from_location'});
                    #my $distAway = sprintf("%.3f", $distAway);
                    
                    print " $stationLabel\n\t$bikesAvail bikes available\n\t$docksAvail docks available\n\t$distAway miles away from your location\n\n\n";
                }
    		} else {
				print "Could not retrieve data from CitiBike: HTTP ".$status;
				exit;
    		}

        } else {
        	print "Could not make handshake with CitiBike server: 500 Internal Server Error";
        	exit;
        }
    } else {
    	print "Could not make handshake with CitiBike server: 500 Internal Server Error";
    	exit;
    }
}

# Start a timer for time to reset
sub startCounter {
    for (my $i=0; $i<$freq; $i++) {
        sleep(1);
        print "\b \b";
    }
}

# Prints the counter as per frequency variable
sub printCounter {
    print "Refreshing in: \n";
    for (my $i=0; $i<$freq; $i++) {
        print "_";
    }
}

# Function makes sure the arguments provided are contained within scope
sub checkArgs {
    $action = lc $action;
	if ($action eq "park" || $action eq "find") {
		return true;
	}

	print "Please specify action: park or find";
	return false;
}

# Function sends a clear cmd to screen based on the OS
sub clearScreen {
	system $^O eq 'MSWin32' ? 'cls' : 'clear';
}

1;
 
__END__

=head1 SYNOPSIS
  
Options:
  
 -a --action=ACTION     Action to take preference to (action or park)
 -f --freq=FREQUENCY    Update frequency (how often to update)