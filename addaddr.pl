#!/usr/bin/perl -w
use strict;
my ($listofips) = @ARGV;
my $iface = $ARGV[2] || "venet0";
my $intnum = $ARGV[1] || 0;
die "Usage: perl -w addaddr.pl file-with-ips mainint firstnum" unless (defined $listofips);

open(IPLIST,$listofips) || die "!!! can\'t read $listofips";

open(IFACES,">>/etc/network/interfaces") || die "!!! can\'t write to interfaces";
while(<IPLIST>){
	my ($ip) = ($_ =~ /(\d+\.\d+\.\d+\.\d+)/);
	print IFACES "auto $iface:$intnum\n";
	print IFACES "iface $iface:$intnum inet static\n";
	print IFACES "     address $ip\n";
	print IFACES "     netmask 255.255.255.255\n\n";
	$intnum++;
}
close(IPLIST);
close(IFACES);
#system("systemctl restart networking") == 0 || die "!!! can\'t apply config" ;

