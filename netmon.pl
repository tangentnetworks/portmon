#!/usr/bin/perl
#
# netmon.pl - Network connection monitor for OpenBSD
# Shows which processes are listening/connected on which ports
#
# Usage: ./netmon.pl [username|program_name]
#

use strict;
use warnings;

my $filter = shift @ARGV;

# Get process information
my %procs;
open(my $ps, '-|', 'ps', 'auxww') or die "Can't run ps: $!\n";
while (<$ps>) {
    next if /^USER/;  # Skip header
    my @fields = split(/\s+/, $_, 11);
    my ($user, $pid, $cmd) = ($fields[0], $fields[1], $fields[10]);
    
    # Extract program name from command
    my $prog = $cmd;
    $prog =~ s/^.*\///;  # Remove path
    $prog =~ s/\s.*$//;  # Remove arguments
    
    $procs{$pid} = {
        user => $user,
        cmd => $cmd,
        prog => $prog
    };
}
close($ps);

# Parse fstat output for network connections
my %connections;
open(my $fstat, '-|', 'fstat') or die "Can't run fstat: $!\n";
while (<$fstat>) {
    next unless /internet/;
    
    my @fields = split(/\s+/);
    my $user = $fields[0];
    my $prog = $fields[1];
    my $pid = $fields[2];
    
    # Extract connection details
    my $type = '';
    my $local = '';
    my $remote = '';
    my $state = '';
    
    if (/internet stream tcp/) {
        for (my $i = 0; $i < @fields; $i++) {
            if ($fields[$i] =~ /^(\d+\.\d+\.\d+\.\d+):(\d+)$/ || 
                $fields[$i] =~ /^([\w:]+):(\d+)$/ ||
                $fields[$i] =~ /^\*:(\d+)$/) {
                if (!$local) {
                    $local = $fields[$i];
                    $remote = $fields[$i+1] if $i+1 < @fields;
                    last;
                }
            }
        }
    } elsif (/internet dgram udp/) {
        $type = 'udp';
        for (my $i = 0; $i < @fields; $i++) {
            if ($fields[$i] =~ /:(\d+)$/) {
                $local = $fields[$i];
                last;
            }
        }
    }
    
    next unless $local;
    
    # Apply filter if specified
    if ($filter) {
        next unless ($user =~ /$filter/ || $prog =~ /$filter/ || $pid eq $filter);
    }
    
    # Determine state
    if ($remote && $remote eq '*.*') {
        $state = 'LISTEN';
    } elsif ($remote) {
        $state = 'ESTABLISHED';
    } else {
        $state = 'BOUND';
    }
    
    push @{$connections{$pid}}, {
        user => $user,
        prog => $prog,
        local => $local,
        remote => $remote || '*.*',
        state => $state,
        cmd => $procs{$pid}->{cmd} || $prog
    };
}
close($fstat);

# Display results
printf "%-12s %-6s %-10s %-22s %-22s %-12s %s\n",
    "USER", "PID", "STATE", "LOCAL", "REMOTE", "PROGRAM", "COMMAND";
print "=" x 140, "\n";

foreach my $pid (sort { $a <=> $b } keys %connections) {
    foreach my $conn (@{$connections{$pid}}) {
        printf "%-12s %-6s %-10s %-22s %-22s %-12s %s\n",
            $conn->{user},
            $pid,
            $conn->{state},
            $conn->{local},
            $conn->{remote},
            $conn->{prog},
            substr($conn->{cmd}, 0, 50);
    }
}

# Summary if filtering
if ($filter && %connections) {
    print "\n";
    my $total = 0;
    $total += scalar @{$connections{$_}} for keys %connections;
    print "Found $total connection(s) matching '$filter'\n";
}