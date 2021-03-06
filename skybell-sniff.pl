#!/usr/bin/perl
# Copyright © 2017 Alexander Thoukydides
# Copyright © 2018 Geekvisit
# 	Geekvisit changes to make it work for button press 

use strict;
use warnings;

use Socket;

# Ensure that standard output is not buffered
$| = 1, select $_ for select STDOUT;

# Process the command line, substituting environment variables
die "$0 SKYBELL-HOST TCPDUMP-COMMAND MOTION-COMMAND\n" unless scalar @ARGV == 3;
foreach my $arg (@ARGV)
{
    $arg =~ s/\$\{(\w+)}/$ENV{$1}/ge;
}
my ($skybell_host, $cmd_tcpdump, $cmd_motion) = @ARGV;

# Timeout (in seconds) to recognise a packet sequence
my $timeout = 10;

# Resolve hostname to a numeric IP address (since that is what tcpdump outputs)
my $skybell_ip_packed = gethostbyname($skybell_host)
    or die "Failed to resolve $skybell_host: $!\n";
my $skybell_ip = inet_ntoa($skybell_ip_packed);

# Start monitoring the SkyBell HD CoAP traffic
open(my $pipe, '-|', $cmd_tcpdump)
    or die "Failed to spawn '$cmd_tcpdump': $!\n";

# Monitor the SkyBell traffic
print "Monitoring SkyBell HD $skybell_host ($skybell_ip)\n";
my $state = 'idle';
my $time = 0;
my $length = 0;
my $priorlength = 0;
while (<$pipe>)
{
    # Parse the tcpdump output
    if (!/(\d+):(\d+):(\d+.\d+) IP (\d+(?:\.\d+){3})\.\d+ > [\.\d]+: UDP, length (\d+)\s*$/)
    {
        print "Unexpected tcpdump format: $_";
        next;
    }
    my $time_delta = (($1 *60) + $2) * 60 + $3;
    my $from_skybell = $4 eq $skybell_ip;
   
    $priorlength = $length;
    $length = $5 + 0;
    if ($length == 49 and $priorlength == 97)
	{
            print "Button Pressed or Motion Detected\n";
            system($cmd_motion) == 0
                or warn "Failed to execute command: $?\n";
	}
    #printf "%10.6f seconds  %4d bytes %4s %s\n",
    #    $time_delta, $length, ($from_skybell ? 'from' : 'to'), $skybell_host;

    # Check for a timeout from the start of the sequence
    if ($state ne 'idle' and $timeout < ($time += $time_delta))
    {
        print "(Returning to idle)\n";
        $state = 'idle';
        $time = 0;
    }

    # Process the sniffed packet
    if ($state eq 'idle')
    {
	 if ($from_skybell and $length == 465)
#	 if ($length == 97)
        {
            print "(Possible motion detected)\n";
            $state = 'armed';
        }
        elsif (not $from_skybell and 800 < $length)
        {
            print "On-demand requested\n";
            $state = 'on-demand';
        }
    }
    elsif ($state eq 'armed')
    {
        if(not $from_skybell and $length == 49)
        {
            print "Motion detected\n";
            $state = 'motion';
            system($cmd_motion) == 0
                or warn "Failed to execute command: $?\n";
        }
    }
}

# Should never reach this point
die "tcpdump process died unexpectedly\n";
