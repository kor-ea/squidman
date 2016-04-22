#!/usr/bin/perl -w
use strict;
my ($listofips) = @ARGV;
my $intnum = $ARGV[1] || 0;
die "Usage: perl -w addaddr.pl file-with-ips" unless (defined $listofips);

open(IPLIST,$listofips) || die "!!! can\'t read $listofips";

while(<IPLIST>){
	my ($ip) = ($_ =~ /(\d+\.\d+\.\d+\.\d+)/);
	print "auto venet0:$intnum\n";
	print "iface venet0:$intnum inet static\n";
	print "     address $ip\n";
	print "     netmask 255.255.255.255\n\n";
	$intnum++;
}
close(IPLIST);

