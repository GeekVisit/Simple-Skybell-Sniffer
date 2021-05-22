#!/usr/bin/perl
# Copyright © 2017 Alexander Thoukydides
# Copyright © 221 Geekvisit 
use strict;
use warnings;

my $cmd_sniff="";
use Socket;
my ($skybell_host, $sniffer, $sniffer_tcpdump, $sniffer_tshark, $cmd_action) = @ARGV;
# Ensure that standard output is not buffered
#
$| = 1, select $_ for select STDOUT;

# Process the command line, substituting environment variables
print "Skybell_host is $skybell_host cmd_action is $cmd_action and sniffer is $sniffer\r\n";

# Sniff the SkyBell traffic:
print "Sniffing SkyBell HD\n";

if ($sniffer eq "tcpdump") {  #beginning of if
$cmd_sniff = $sniffer_tcpdump; 
#
####################################################
#  TCPDUMP
####################################################
print "\r\nExecuting tcpdump: $cmd_sniff\r\n";

 my $skybell_ip = $skybell_host; 


# Timeout (in seconds) to recognise a packet sequence
my $timeout = 10;


# Start Sniffing the SkyBell HD CoAP traffic
open(my $pipe, '-|', $cmd_sniff)
    or die "Failed to spawn '$cmd_sniff': $!\n";

# Sniff the SkyBell traffic
print "Sniffing SkyBell HD $skybell_host ($skybell_ip)\n";
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
            system($cmd_action) == 0
                or warn "Failed to execute command: $?\n";
	}

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
            system($cmd_action) == 0
                or warn "Failed to execute command: $?\n";
        }
    }
} 
} else {   #end of if


####################################################
#  Wire/Tshark
####################################################

$cmd_sniff = $sniffer_tshark; 
print "Executing tshark: $cmd_sniff\r\n";

 open(my $pipe, '-|', "$cmd_sniff" ) or die "Failed to start tshark\n";

my $length = 0;     
my $priorlength = 0;
while (<$pipe>)
{

    #  print sprintf ("Length is %s..\r\n", $length);

if ($length != 186  and $length != 986)
{
if ($priorlength == 186) { 
print "skybell sniffer: Button Pressed or Motion Detected\n";
#execute commands to ring bell or whatever
system($cmd_action) == 0
    or warn "Failed to execute command: $?\n";
    }
}
}
}

# Should never reach this point
die "Error: Skybell sniffer process died unexpectedly - run skybell-sniff.pl directly and check for permission or other errors\n";
