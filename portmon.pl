#!/usr/bin/perl
#
# portmon.pl - Enhanced port and connection monitor for OpenBSD
# Shows listening ports and active connections with process details
#
# Usage: ./portmon.pl [options] [filter]
#   -l          Show only listening ports
#   -e          Show only established connections
#   -a          Show all connections (default)
#   filter      Username, program name, or PID to filter
#

use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('lea', \%opts);

my $show_listen = $opts{l} || $opts{a} || (!$opts{l} && !$opts{e});
my $show_established = $opts{e} || $opts{a} || (!$opts{l} && !$opts{e});
my $filter = shift @ARGV;

# Build process map
my %procs;
open(my $ps, '-|', 'ps', 'auxww') or die "Can't run ps: $!\n";
while (<$ps>) {
    next if /^USER/;
    my @f = split(/\s+/, $_, 11);
    my $prog = $f[10];
    $prog =~ s/^.*\///;
    $prog =~ s/[\s:].*$//;
    $procs{$f[1]} = { user => $f[0], prog => $prog, cmd => $f[10] };
}
close($ps);

# Parse netstat for socket information
my %sockets;
open(my $netstat, '-|', 'netstat', '-na', '-f', 'inet', '-f', 'inet6') or die "Can't run netstat: $!\n";
while (<$netstat>) {
    next if /^Active/ || /^Proto/;
    
    my ($proto, $recv, $send, $local, $foreign, $state) = split(/\s+/);
    next unless $proto =~ /^tcp/;
    
    # Normalize addresses
    $local =~ s/^(\*|\:\:)\.(\d+)$/*:$2/;
    $foreign =~ s/^\*\.\*$/*:*/;
    
    # Extract port from local address
    my ($port) = $local =~ /:(\d+)$/;
    next unless $port;
    
    $sockets{$local}{$foreign}{$state} = 1;
}
close($netstat);

# Parse fstat to map sockets to processes
my @results;
open(my $fstat, '-|', 'fstat', '-n') or die "Can't run fstat: $!\n";
while (<$fstat>) {
    next unless /internet.*tcp/;
    
    my @f = split(/\s+/);
    my ($user, $prog, $pid) = @f[0..2];
    
    # Extract socket addresses from fstat output
    my $local;
    my $foreign;
    
    for (my $i = 3; $i < @f; $i++) {
        if (defined $f[$i] && ($f[$i] =~ /^\d+\.\d+\.\d+\.\d+:\d+$/ || 
            $f[$i] =~ /^[\w:]+:\d+$/ ||
            $f[$i] =~ /^\*:\d+$/)) {
            $local = $f[$i];
            $foreign = (defined $f[$i+1] ? $f[$i+1] : undef);
            last;
        }
    }
    next unless defined $local;
    
    $foreign //= '*.*';
    $foreign =~ s/^\*\.\*$/*:*/;
    
    # Determine state
    my $state = 'UNKNOWN';
    if (!defined($foreign) || $foreign eq '*:*' || $foreign eq '*.*') {
        $state = 'LISTEN';
    } elsif ($foreign =~ /:\d+$/) {
        $state = 'ESTABLISHED';
    }
    
    # Apply filter
    if (defined $filter) {
        next unless ($user =~ /$filter/i || $prog =~ /$filter/i || $pid eq $filter);
    }
    
    # Apply state filter
    next if ($state eq 'LISTEN' && !$show_listen);
    next if ($state eq 'ESTABLISHED' && !$show_established);
    
    my $proc_info = $procs{$pid} || { user => $user, prog => $prog, cmd => $prog };
    
    push @results, {
        user => $user,
        pid => $pid,
        prog => $prog,
        local => $local,
        foreign => $foreign // '*:*',
        state => $state,
        cmd => $proc_info->{cmd}
    };
}
close($fstat);

# Display results
if (@results) {
    printf "%-12s %-7s %-15s %-28s %-28s %-12s\n",
        "USER", "PID", "PROGRAM", "LOCAL ADDRESS", "FOREIGN ADDRESS", "STATE";
    print "=" x 120, "\n";
    
    foreach my $r (sort { 
        $a->{state} cmp $b->{state} || 
        $a->{local} cmp $b->{local} ||
        $a->{pid} <=> $b->{pid} 
    } @results) {
        printf "%-12s %-7s %-15s %-28s %-28s %-12s\n",
            $r->{user},
            $r->{pid},
            substr($r->{prog}, 0, 15),
            $r->{local},
            $r->{foreign},
            $r->{state};
    }
    
    print "\nTotal: ", scalar(@results), " connection(s)\n";
} else {
    print "No connections found";
    print " matching '$filter'" if $filter;
    print "\n";
}